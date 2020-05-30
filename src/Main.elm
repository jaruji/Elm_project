module Main exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http exposing (..)
import Url
import Url.Parser as Parser exposing (Parser, (</>), (<?>), custom, fragment, map, oneOf, s, top)
import Url.Parser.Query as Query
import Json.Decode as Decode
import Json.Encode as Encode
import FeatherIcons as Icons
import Pages.Gallery as Gallery
import Pages.SignUp as SignUp
import Pages.SignIn as SignIn
import Pages.Upload as Upload
import Pages.Home as Home
import Pages.Profile as Profile
import Pages.Users as Users
import Pages.Post as Post
import Pages.Results as Results
import Pages.Tags as Tags
import Components.SearchBar as Search
import Components.Carousel as Carousel
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Session
import User
import Server
import ElmLogo as Logo
import Svg
import Svg.Attributes as SvgAttrs
--elm-live src/Main.elm -u -- --output=elm.js (will start server on localhost with pushstate enabled)

{--
  Our main is using Browser.application function, so we can intercept URL changes and react
  to them by serving our own Pages.
--}
main : Program (Maybe String) Model Msg
main =
  Browser.application
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    , onUrlChange = UrlChange
    , onUrlRequest = UrlRequest
    }

-- MODEL
--page: represents the currently displayed Page, each page is defined in /Page directory
--search: SearchBar component
--state: represents the global state of our application
type alias Model =
  { key: Nav.Key
  , url: Url.Url
  , page: Page
  , search: ( Search.Model, Cmd Search.Msg )
  , state: State
  }

type Page 
  = NotFound String
  | Loading
  | Gallery Gallery.Model
  | SignUp SignUp.Model
  | SignIn SignIn.Model
  | Upload Upload.Model
  | Home Home.Model
  | Profile Profile.Model
  | Users Users.Model
  | Post Post.Model
  | Tags Tags.Model
  | Results Results.Model

{--
  Multiple states of our app. Most of the time our app is ready,
  meaning it is fully working. If we have a session token stored in LocalStorage
  on application init, state NotReady is chosen. The app will attempt to authenticate
  the user, if it succeeds state will change to Ready.  If it fails with BadRequest, the
  state will still change to Ready but session value will be Nothing! If server issue arises,
  Failure state will be chosen.
--}
type State
  = Ready Session.Session
  | NotReady String
  | Failure

--Multiple Msg required for correct funcionality of single page application
type Msg
  = UrlRequest Browser.UrlRequest
  | UrlChange Url.Url
  --converter types
  | GalleryMsg Gallery.Msg 
  | SignUpMsg SignUp.Msg
  | SignInMsg SignIn.Msg
  | HomeMsg Home.Msg
  | UploadMsg Upload.Msg
  | ProfileMsg Profile.Msg
  | UsersMsg Users.Msg
  | UpdateSearch Search.Msg
  | PostMsg Post.Msg
  | ResultsMsg Results.Msg
  | TagsMsg Tags.Msg
  --logout using ports (User.elm)
  | LogOut
  --Handle server response when authenticating based on token in LocalStorage
  | Response (Result Http.Error User.Model)

init : Maybe String -> Url.Url -> Nav.Key -> (Model, Cmd Msg)
init flag url key =
  case flag of
    -- If no entry in localStorage, user is not signed in
    Nothing ->
      routeUrl url 
        { key = key
        , url = url
        , page = Loading
        , search = Search.init key
        , state = Ready Session.init
        }
    -- If there is a token in localStorage, use it to authenticate user (state NotReady)
    Just token -> 
      routeUrl url 
        { key = key
        , url = url
        , page = Loading
        , search = Search.init key
        , state = NotReady token
        }
    
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UrlRequest urlRequest ->
      --handle internal and external URL's
      case urlRequest of
        Browser.Internal url ->
          -- if URL belongs to our app, use Nav.pushUrl to add it to our url
          (model, Nav.pushUrl model.key (Url.toString url))

        Browser.External url ->
          {-- 
            If URL belongs to external website, we need to load it using Nav.load.
            This will cause a page load! So when we come back, state that was not saved
            will be lost
          --}
          (model, Nav.load url)

    UrlChange url ->
      --use routeUrl function to react to all URL changes
      routeUrl url model

    LogOut ->
      --log the user out by calling User.logout port function
      ( { model | state = Ready Session.init }, User.logout )
  
    ------------------------------------------------------------------------

    {-- 
      following messages are used for converting the values returned by update function to
      (Model, Cmd Msg). This solution was inspired by https://github.com/elm/package.elm-lang.org
    --}

    UpdateSearch mesg -> 
      stepSearch model (Search.update mesg (Search.getModel model.search))

    SignUpMsg mesg ->
      case model.page of
        SignUp signup -> 
          stepSignUp model (SignUp.update mesg signup)
        _ ->
          (model, Cmd.none)

    SignInMsg mesg ->
      case model.page of
        SignIn signin -> 
          stepSignIn model (SignIn.update mesg signin)
        _ -> 
          (model, Cmd.none)

    GalleryMsg mesg ->
      case model.page of
        Gallery gallery ->
          stepGallery model (Gallery.update mesg gallery)
        _ -> 
          ( model, Cmd.none )

    UploadMsg mesg ->
      case model.page of
        Upload upload ->
          stepUpload model (Upload.update mesg upload)
        _ -> 
          ( model, Cmd.none )

    HomeMsg mesg ->
      case model.page of
        Home home -> 
          stepHome model (Home.update mesg home)
        _ -> 
          ( model, Cmd.none )

    ProfileMsg mesg ->
      case model.page of
        Profile profile ->
          stepProfile model (Profile.update mesg profile)
        _ -> 
          (model, Cmd.none)

    UsersMsg mesg ->
      case model.page of
        Users users -> 
          stepUsers model (Users.update mesg users)
        _ -> 
          (model, Cmd.none)

    PostMsg mesg ->
      case model.page of
        Post post -> 
          stepPost model (Post.update mesg post)
        _ -> 
          (model, Cmd.none)

    ResultsMsg mesg ->
      case model.page of
        Results results -> 
          stepResults model (Results.update mesg results)
        _ -> 
          (model, Cmd.none)

    TagsMsg mesg ->
      case model.page of
        Tags tags -> 
          stepTags model (Tags.update mesg tags)
        _ -> 
          (model, Cmd.none)

    ------------------------------------------------------------

    Response response ->
      case response of
        Ok user ->
          --page refresh without calling init! Logs in user by using Session.set function.
          ({ model | state = Ready (Session.set user) }, Nav.pushUrl model.key (Url.toString model.url))
        Err log ->
          case log of
            BadStatus code -> 
              --if invalid token, user gets logged out of the app
              ({ model | state = Ready Session.init }, Cmd.batch[ User.logout, Nav.reload ])
            _ ->
              --if other error, means server is having issues so the app won't work
              ({ model | state = Failure }, Cmd.none)

--these are the functions used for converting Model and Msg of subtypes to Main type.
--With this approach we can separate each component and page as their own modules, while
--still handling their internal Msg and also all Cmd Msg. All these functions are essentially equal,
--as they only convert the values produced by our imported modules.

stepTags: Model -> (Tags.Model, Cmd Tags.Msg) -> (Model, Cmd Msg)
stepTags model (tags, cmd) =
  ({ model | page = Tags tags }, Cmd.map TagsMsg cmd)

stepResults: Model -> (Results.Model, Cmd Results.Msg) -> (Model, Cmd Msg)
stepResults model (results, cmd) =
  ({ model | page = Results results }, Cmd.map ResultsMsg cmd)

stepPost: Model -> (Post.Model, Cmd Post.Msg) -> (Model,Cmd Msg)
stepPost model (post, cmd) =
  ({ model | page = Post post }, Cmd.map PostMsg cmd)

stepUsers: Model -> (Users.Model, Cmd Users.Msg) -> (Model, Cmd Msg)
stepUsers model (users, cmd) =
  ({ model | page = Users users }, Cmd.map UsersMsg cmd) 
  
stepProfile: Model -> (Profile.Model, Cmd Profile.Msg) -> (Model, Cmd Msg)
stepProfile model (profile, cmd) =
  ({ model | page = Profile profile }, Cmd.map ProfileMsg cmd)

stepSearch: Model -> (Search.Model, Cmd Search.Msg) -> (Model, Cmd Msg)
stepSearch model (search, cmd) =
  ({ model | search = (search, cmd) }, Cmd.map UpdateSearch cmd)

stepHome : Model -> (Home.Model, Cmd Home.Msg) -> (Model, Cmd Msg)
stepHome model (home, cmd) =
  ({ model | page = Home home }, Cmd.map HomeMsg cmd)
  
stepUpload : Model -> (Upload.Model, Cmd Upload.Msg) -> (Model, Cmd Msg)
stepUpload model (upload, cmd) = 
  ({ model | page = Upload upload }, Cmd.map UploadMsg cmd)

stepSignUp : Model -> (SignUp.Model, Cmd SignUp.Msg) -> (Model, Cmd Msg)
stepSignUp model (signup, cmd) =
  ({ model | page = SignUp signup }, Cmd.map SignUpMsg cmd)

stepSignIn : Model -> (SignIn.Model, Cmd SignIn.Msg, Session.UpdateSession) -> (Model, Cmd Msg)
stepSignIn model (signin, cmd, session) = 
  --shared state! By using message contained in signin update, we can transform state in main 
  ({ model | page = SignIn signin, state = Ready (Session.update session Session.init) }, Cmd.map SignInMsg cmd)

stepGallery : Model -> (Gallery.Model, Cmd Gallery.Msg) -> (Model, Cmd Msg)
stepGallery model (gallery, cmd) = 
  ({ model | page = Gallery gallery } , Cmd.map GalleryMsg cmd)

subscriptions : Model -> Sub Msg
subscriptions model =
  --using this approach, we can manage the subscriptions of our pages one at a time
  --this means we don't have to worry about multiple subscriptions running at the same time
  case model.page of
    Home home ->
      Home.subscriptions home |> Sub.map HomeMsg
    Post post ->
      Post.subscriptions post |> Sub.map PostMsg
    Tags tags ->
      Tags.subscriptions tags |> Sub.map TagsMsg
    _ ->
      Sub.none

view : Model -> Browser.Document Msg
view model =
    --view function that handles the display of each page. This approach is good because it
    --supports consistency, as we can always use the same page structure. Only thing we swap is
    --the content of each page, while we can even use the view function of each page.
    case model.page of
      NotFound string ->
        { title = "Not Found"
        , body = [
          viewHeader model
          , viewBody model string
          , viewFooter
          ]
        }
      Loading ->
        { title = "Fetching data"
        , body = [
          viewHeader model
          , viewLoading model
          , viewFooter
        ]
        }
      Home home ->
        { title = "Home"
        , body = [
          viewHeader model
          , Home.view home |> Html.map HomeMsg
          , viewFooter
          ]
        }
      Gallery gallery ->
        { title = "Gallery"
        , body = [
          viewHeader model
          , div [class "body"][
            Gallery.view gallery |> Html.map GalleryMsg
          ]
          , viewFooter        
          ]
        }
      SignUp signup ->
        { title = "Sign up"
        , body = [
          viewHeader model
          , div[class "body"][
           SignUp.view signup |> Html.map SignUpMsg
          ]
          , viewFooter
          ]
        }
      SignIn signin ->
        { title = "Sign in"
        , body = [
          viewHeader model
          , div[class "body"][
           SignIn.view signin |> Html.map SignInMsg
          ]
          --, viewBody model
          , viewFooter
          ]
        }
      Upload upload ->
        { title = "Upload an image"
        , body = [
          viewHeader model
          , div[class "body"][
           Upload.view upload |> Html.map UploadMsg
          ]
          , viewFooter
          ]
        }
      Profile profile ->
        { title = profile.user.username
          , body = [
            viewHeader model
            , div [style "text-align" "center", style "padding-top" "50px" ][
              Profile.view profile |> Html.map ProfileMsg
            ]
            , viewFooter
          ]
        }
      Users users -> 
        { title = "Users"
          , body = [
            viewHeader model
            , div[class "body"][
              Users.view users |> Html.map UsersMsg
            ]
            , viewFooter
          ]
        }   
      Post post -> 
        { title = post.title
          , body = [
            viewHeader model
            , div[class "body"][
              Post.view post |> Html.map PostMsg
            ]
            , viewFooter
          ]
        }
      Results results -> 
        { title = "Search results"
          , body = [
            viewHeader model
            , div[class "body"][
              Results.view results |> Html.map ResultsMsg
            ]
            , viewFooter
          ]
        }
      Tags tags -> 
        { title = "Tags"
          , body = [
            viewHeader model
            , div[class "body"][
              Tags.view tags |> Html.map TagsMsg
            ]
            , viewFooter
          ]
        }

viewHeader: Model -> Html Msg
viewHeader model = 
  div [ class "navbar navbar-inverse navbar-fixed-top", style "opacity" "0.95" ]
    [ 
      div [ class "container-fluid" ][
        div [ class "navbar-header" ][
          div [ class "navbar-brand" ][ 
            a [ href "/", class "preview" ][
              Svg.svg [ SvgAttrs.width "35"
              , SvgAttrs.viewBox "0 0 35 35" ][ 
                Logo.svg 35 
              ]
            ]
          ]
        ]
        , ul [ class "nav navbar-nav" ][
            --if currently displayed page is equal to the page the link redirects to
            --we color it white so it is obvious we are currently showing exactly that page
            li [] [ a [ href "/", case model.page of 
              Home _ -> style "color" "white" 
              _ -> style "" "" ] [ text "Home" ] ]
            , li [] [ a [ href "/gallery?page=1&sort=newest", case model.page of 
              Gallery _ -> style "color" "white" 
              _ -> style "" "" ] [ text "Gallery" ] ]
            , li [] [ a [ href "/upload", case model.page of 
              Upload _ -> style "color" "white" 
              _ -> style "" "" ] [ text "Upload" ] ]
            , li [] [ a [ href "/users", case model.page of 
              Users _ -> style "color" "white" 
              _ -> style "" "" ] [ text "Users" ] ]
            , li [] [ a [ href "/tags", case model.page of 
              Tags _ -> style "color" "white" 
              _ -> style "" "" ] [ text "Tags" ] ]
            , li [] [ Search.view (Search.getModel model.search) |> Html.map UpdateSearch ]
        ]
        , case getUser model.state of
            --the navbar differs when we are logged in. If we are logged out, we obviously
            --display the Sign In and Sign Up options. These are no longer necessary when user
            --logs in, so we swap them to profile link and logout option!
            Nothing ->
              ul [ class "nav navbar-nav navbar-right" ][
                li [] [ a [ href "/sign_in" , case model.page of 
                  SignIn _ -> style "color" "white" 
                  _ -> style "" "" ] [ span [class "glyphicon glyphicon-user"][], text " Sign In"] ]
                , li [] [ a [ href "/sign_up" , case model.page of 
                  SignUp _ -> style "color" "white" 
                  _ -> style "" "" ] [ span [class "glyphicon glyphicon-user"][], text " Sign Up"] ]
              ]
            Just user ->
             ul [ class "nav navbar-nav navbar-right" ][
              li [][
                img [ class "avatar"
                , attribute "draggable" "false"
                , style "border-radius" "50%"
                , style "margin-top" "5px"
                , src user.avatar
                , height 40
                , width 40 ] [] 
              ]
              , li [] [ a [ href ("/profile/" ++ user.username), case model.page of 
                Profile _ -> style "color" "white" 
                _ -> style "" "" ]  [ text user.username ] ]
              , li [] [ a [ onClick LogOut ] [ span [ class "glyphicon glyphicon-log-out", style "margin-right" "2px" ][], text "Log Out" ] ]
             ]
      ] 
    ]

viewBody: Model -> String -> Html Msg
viewBody model error =
  --view body of error page where the error is obtained as parameter so we can reuse it
  div [ style "height" "800px", style "margin-top" "25%", style "text-align" "center" ] [
    h2 [] [ text error ]
  ]

viewLoading: Model -> Html Msg
viewLoading model =
  --view that shows up if the app is loading some data
  div [ style "height" "800px", style "margin-top" "25%", style "text-align" "center" ] [
    h2 [] [ text "Fetching data from the server" ]
    , Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
  ]

viewFooter: Html Msg
viewFooter =
  --simple footer
  div [ style "bottom" "0%"
  , style "height" "100px"
  , style "text-align" "center"
  , style "color" "white"
  , style "padding-top" "25px"
  , style "background-color" "#222"
  , style "opacity" "0.98"
  , class "container-fluid text-center"
  , style "margin-top" "20px" ][ 
    ul [ style "margin-top" "20px" ] [
      li [ class "nav" ][
        a [ href "https://github.com/jaruji/Elm_project"
        , style "color" "white"
        , class "preview" ][
          text "© 2020 Juraj Bedej" 
        ]
      ]
    ]
  ]

--Router
--entire routing logic is defined in this function (url and what Model+Cmd it should produce)
routeUrl : Url.Url -> Model -> (Model, Cmd Msg)
routeUrl url model =
  --function that allows us to handle URL's and choose how to handle them
  let
    parser =
      Parser.oneOf  --parser will be one of these (these are almost always used together!)
        [ 
          {--
            Explanation: We need to handle (detect) the URL and we also need a function that will 
            be executed when we detect this url. We use Parser.map to connect these two together, and after obtaining
            the parser value we can use Url.Parse.parse to handle this parser and produce results. This code is the main logic behind single
            page application routing.
          --}
          (s "gallery" <?> Query.int "page" <?> Query.string "sort")
            |> Parser.map 
              (\page sort -> stepGallery model (Gallery.init (getUser model.state) model.key page sort))
          , (s "sign_up") 
            |> Parser.map (stepSignUp model (SignUp.init model.key))
          , (s "sign_in")
            |> Parser.map (stepSignIn model (SignIn.init model.key))
          , (s "upload")
            |> Parser.map (stepUpload model (Upload.init (getUser model.state) model.key))
          , (top)
            |> Parser.map (stepHome model (Home.init (getUser model.state) model.key))
          , (s "profile" </> Parser.string)
            |> Parser.map 
              ( case getUser model.state of
                Just userAcc ->
                  (\user ->
                    stepProfile model (Profile.init model.key userAcc user)
                  )
                _ ->
                  (\user ->
                    ({model | page = NotFound "You must be logged in to do this"}, Cmd.none)
                  )
              )
          , (s "users")
            |> Parser.map (stepUsers model (Users.init model.key))
          , (s "post" </> Parser.string)
            |> Parser.map
              (
                case model.state of
                  Ready session ->
                    (\id -> stepPost model (Post.init model.key session.user id))
                  _ ->
                    (\id -> (model, Cmd.none))
              )
          , (s "search" <?> Query.string "q")
            |> Parser.map (\q -> stepResults model (Results.init q))
          , (s "tags" <?> Query.string "q")
            |> Parser.map (\q -> stepTags model (Tags.init model.key q))
        ]
  in 
  case model.state of
        --we only parse the url when our App state is Ready. If it's not, we wait for the
        --state to reslove first!
        NotReady token ->
          ({ model | page = Loading }, loadUser token)

        _ ->
          --we use Maybe.withDefault in combination with Url.Parse.parse (if result of parse is Nothing, page not found will be shown)
          Maybe.withDefault ({ model | page = NotFound "Oops, this page doesn't exist!" }, Cmd.none) (Parser.parse parser url) 

--getter for user from current state
getUser: State -> Maybe User.Model
getUser state =
  case state of
    Ready session ->
      case session.user of
        Just user ->
          Just user
        Nothing ->
          Nothing
    _ ->
      Nothing

--use this function if user token is stored in local storage
--authenticates user based on token stored in ls
loadUser: String -> Cmd Msg
loadUser token =
  Http.request
    { method = "GET"
    , headers = [ Http.header "auth" token ]
    , url = Server.url ++ "/account/auth"
    , body = Http.emptyBody 
    , expect = Http.expectJson Response User.decodeUser
    , timeout = Nothing
    , tracker = Nothing
    }