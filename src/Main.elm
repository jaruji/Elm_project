module Main exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Url
import Url.Parser as Parser exposing (Parser, (</>), custom, fragment, map, oneOf, s, top)
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
import Components.SearchBar as Search
import Components.Carousel as Carousel
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Session
import User
import Server
--import Components.SingUp as SignUp

--97, 113, 181?

--usage - type the following command into terminal (need to install elm-live)
--elm-live src/Main.elm --open -- --output=elm.js (will start server on localhost)

-- MAIN

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
  --under here SignUp (SignUp.Model, Cmd SignUp.Msg)
  | SignUp SignUp.Model
  | SignIn SignIn.Model
  | Upload Upload.Model
  | Home Home.Model
  | Profile Profile.Model
  | Users Users.Model
  | Post Post.Model

type State
  = Ready Session.Session
  | NotReady String
  | Failure

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
  | LogOut
  | Response (Result Http.Error User.Model)

init : Maybe String -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flag url key =
  case flag of
    Nothing ->
      routeUrl url  --if no entry in localStorage, user is not signed in
        { key = key
        , url = url
        , page = NotFound ""
        , search = Search.init key
        , state = Ready Session.init
        }
    Just token -> -- if there is a token in localStorage, use it to load user info
      routeUrl url  --if no entry in localStorage, user is not signed in
        { key = key
        , url = url
        , page = NotFound ""
        , search = Search.init key
        , state = NotReady token
        }
    
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UrlRequest urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model, Nav.pushUrl model.key (Url.toString url) )

        Browser.External href ->
          ( model, Nav.load href )

    UrlChange url ->
      routeUrl url model

    LogOut ->
      ( { model | state = Ready Session.init }, User.logout ) --?? bugged
    
    UpdateSearch mesg -> 
       --({ model | search = Search.update mesg (Search.getModel model.search) }, Cmd.none)
       stepSearch model (Search.update mesg (Search.getModel model.search))

    SignUpMsg mesg ->
      case model.page of
        SignUp signup -> stepSignUp model (SignUp.update mesg signup)
          --this was not working together with cmd! the other approach works though
          --({model | page = SignUp (SignUp.update mesg signup)}, Cmd.none)
          --       -> (model, Cmd.none)
        _ -> (model, Cmd.none)

    SignInMsg mesg ->
      case model.page of
        SignIn signin -> 
          stepSignIn model (SignIn.update mesg signin)
          --stepSignIn model (SignIn.update mesg signin)
          --({model | page = SignIn (SignIn.update mesg signin)}, Cmd.none)
        _ -> (model, Cmd.none)

    GalleryMsg mesg ->
      case model.page of
        Gallery gallery -> stepGallery model (Gallery.update mesg gallery)
        _ -> ( model, Cmd.none )

    UploadMsg mesg ->
      case model.page of
        Upload upload -> stepUpload model (Upload.update mesg upload)
        _ -> ( model, Cmd.none )

    HomeMsg mesg ->
      case model.page of
        Home home -> stepHome model (Home.update mesg home)
        _ -> ( model, Cmd.none )

    ProfileMsg mesg ->
      case model.page of
        Profile profile -> stepProfile model (Profile.update mesg profile)
        _ -> (model, Cmd.none)

    UsersMsg mesg ->
      case model.page of
        Users users -> stepUsers model (Users.update mesg users)
        _ -> (model, Cmd.none)

    PostMsg mesg ->
      case model.page of
        Post post -> stepPost model (Post.update mesg post)
        _ -> (model, Cmd.none)

    Response response ->
      case response of
        Ok user ->
          ({ model | state = Ready (Session.set user) }, Nav.pushUrl model.key (Url.toString model.url))
          --page refresh without calling init!
        Err log ->
          ({ model | state = Failure}, Cmd.none)

stepPost: Model -> (Post.Model, Cmd Post.Msg) -> (Model,Cmd Msg)
stepPost model (post, cmd) =
  ({ model | page = Post post }, Cmd.map PostMsg cmd)

stepUsers: Model -> (Users.Model, Cmd Users.Msg) -> (Model, Cmd Msg)
stepUsers model (users, cmd) =
  ({ model | page = Users users }, Cmd.map UsersMsg cmd) 
  
stepProfile: Model -> (Profile.Model, Cmd Profile.Msg, Session.UpdateSession) -> (Model, Cmd Msg)
stepProfile model (profile, cmd, session) =
  case model.state of
    Ready sess ->
      ({ model | page = Profile profile, state = Ready (Session.update session sess) }, Cmd.map ProfileMsg cmd)
    _ -> 
      (model, Cmd.none)

stepSearch: Model -> (Search.Model, Cmd Search.Msg) -> (Model, Cmd Msg)
stepSearch model ( search, cmd ) =
  ({ model | search = (search, cmd) }, Cmd.map UpdateSearch cmd)

stepHome : Model -> (Home.Model, Cmd Home.Msg) -> (Model, Cmd Msg)
stepHome model ( home, cmd ) =
  ({ model | page = Home home }, Cmd.map HomeMsg cmd)
  
stepUpload : Model -> (Upload.Model, Cmd Upload.Msg) -> (Model, Cmd Msg)
stepUpload model ( upload, cmd ) = 
  ({ model | page = Upload upload }, Cmd.map UploadMsg cmd)

stepSignUp : Model -> (SignUp.Model, Cmd SignUp.Msg) -> (Model, Cmd Msg)
stepSignUp model ( signup, cmd ) =
  ({ model | page = SignUp signup }, Cmd.map SignUpMsg cmd)

--shared state!! by using message contained in signin update, i can transform state in main 
stepSignIn : Model -> (SignIn.Model, Cmd SignIn.Msg, Session.UpdateSession) -> (Model, Cmd Msg)
stepSignIn model ( signin, cmd, session ) = 
  ({ model | page = SignIn signin, state = Ready (Session.update session Session.init) }, Cmd.map SignInMsg cmd)

stepGallery : Model -> (Gallery.Model, Cmd Gallery.Msg) -> (Model, Cmd Msg)
stepGallery model ( gallery, cmd ) = 
  ({ model | page = Gallery gallery } , Cmd.map GalleryMsg cmd)

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  case model.page of
    Home home ->
      Home.subscriptions home |> Sub.map HomeMsg
    _ ->
      Sub.none
 
-- VIEW

view : Model -> Browser.Document Msg
view model =
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
          --, viewBanner model (Server.url ++ "/img/test.jpg")
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
        { title = "Profile"
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
        { title = "Post"
          , body = [
            viewHeader model
            , div[class "body"][
              Post.view post |> Html.map PostMsg
            ]
            , viewFooter
          ]
        }

viewImage : String -> Int -> Int -> Html msg
viewImage path w h =
  img[src path, width w, height h] []

viewHeader: Model -> Html Msg
viewHeader model = 
  div [ class "navbar navbar-inverse navbar-fixed-top", style "opacity" "0.95" ]
    [ 
      div [ class "container-fluid" ][
        div [ class "navbar-header" ][
          div [ class "navbar-brand" ][ 
            viewImage "../src/img/Elm_logo.svg.png" 35 35 
            ]
        ]
        , ul [ class "nav navbar-nav" ][
            li [] [ a [ href "/", case model.page of 
              Home _ -> style "color" "white" 
              _ -> style "" "" ] [ text "Home" ] ]
            , li [] [ a [ href "/gallery", case model.page of 
              Gallery _ -> style "color" "white" 
              _ -> style "" "" ] [ text "Gallery" ] ]
            , li [] [ a [ href "/upload", case model.page of 
              Upload _ -> style "color" "white" 
              _ -> style "" "" ] [ text "Upload" ] ]
            , li [] [ a [ href "/users", case model.page of 
              Users _ -> style "color" "white" 
              _ -> style "" "" ] [ text "Users" ] ]
            , li [] [ Search.view (Search.getModel model.search) |> Html.map UpdateSearch ]
        ]
        
        , case getUser model.state of
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
             ul [ class "nav navbar-nav navbar-right" ] [
              li [] [ img [ class "avatar", style "border-radius" "50%", style "margin-top" "5px", src user.avatar, height 40, width 40 ] [] ]
              , li [] [ a [ href ("/profile/" ++ user.username), case model.page of 
                Profile _ -> style "color" "white" 
                _ -> style "" "" ]  [ text user.username ] ]
              , li [] [ a [ onClick LogOut ] [ span [ class "glyphicon glyphicon-log-out", style "margin-right" "2px" ][], text "Log Out" ] ]
             ]
      ] 
    ]

viewBody: Model -> String -> Html Msg
viewBody model error =
  div [ style "height" "800px", style "margin-top" "25%", style "text-align" "center" ] [
    h2 [] [ text error ]
  ]

viewLoading: Model -> Html Msg
viewLoading model =
  div [ style "height" "800px", style "margin-top" "25%", style "text-align" "center" ] [
    h2 [] [ text "Fetching data from the server" ]
    , Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
  ]

viewFooter: Html Msg
viewFooter =
  div 
  [
      style "background-color" "white"
      , style "bottom" "0%"
      , style "height" "100px"
      , style "text-align" "center"
      , style "color" "white"
      , style "padding-top" "25px"
      , style "background-color" "#2f2f2f"
      , class "container-fluid text-center"
  ] [ 
    ul [ class "nav nav-pills" ] [
      li [][ a [ href "https://github.com/jaruji?tab=repositories", style "color" "white" ] [ text "© 2020 Juraj Bedej" ] ]
    ]
  ]

--Router

routeUrl : Url.Url -> Model -> (Model, Cmd Msg)
routeUrl url model =
  let
    parser =
      oneOf   --rerouting based on url change!
        [ route (s "gallery")
            ( 
              stepGallery model (Gallery.init (getUser model.state) model.key )
            )
          , route (s "sign_up")
            ( 
              stepSignUp model (SignUp.init model.key)
            )
          , route (s "sign_in")
            (
              stepSignIn model ( SignIn.init model.key  )
            )
          , route (s "upload")
            ( 
              stepUpload model (Upload.init (getUser model.state) model.key )
            )
          , route (top)
            ( 
              stepHome model (Home.init (getUser model.state) model.key)
            )
          , route (s "profile" </> getSlug)
            ( 
              case getUser model.state of
                Just userAcc ->
                  (\user ->
                    stepProfile model (Profile.init model.key userAcc user)
                  )
                _ ->
                  (\user ->
                    ({model | page = NotFound "You must be logged in to do this"}, Cmd.none)
                  )
            )
          , route (s "users")
          (
            stepUsers model (Users.init model.key)
          )
          , route (s "post" </> getSlug)
          (
            case model.state of
              Ready session ->
                (\id -> stepPost model (Post.init model.key session.user id))
              _ ->
                (\id -> (model, Cmd.none))
          )
        ]
  in 
    case model.state of
          NotReady token ->
            ( {model | page = Loading }, loadUser token )

          Failure ->
            ( {model | page = NotFound "We are currently having server issues, please try again later"}, Cmd.none)
          
          _ ->
            case Parser.parse parser url of
              Just urll ->
                urll

              Nothing ->
                ({model | page = NotFound "Oops, this page doesn't exist!"}, Cmd.none)

getSlug : Parser (String -> a) a
getSlug =
  --s "user" </> Parser.string
  custom "slug" Just --??? dont get how this works tbh

route : Parser a b -> a -> Parser (b -> c) c
route parser handler =
  Parser.map handler parser

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


--encode user token retrieved from local storage so we can send it to the server
tokenEncoder: String -> Encode.Value
tokenEncoder token =
  Encode.object[("token", Encode.string token)]


--use this function if user token is stored in local storage
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