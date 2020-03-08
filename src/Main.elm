module Main exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Url
import Url.Parser as Parser exposing (Parser, (</>), custom, fragment, map, oneOf, s, top)
import Json.Decode as Json
import FeatherIcons as Icons
import Pages.Gallery as Gallery
import Pages.SignUp as SignUp
import Pages.SignIn as SignIn
import Pages.Upload as Upload
import Components.SearchBar as Search
import Components.Carousel as Carousel
--import Components.SingUp as SignUp

--97, 113, 181?

--usage - type the following command into terminal (need to install elm-live)
--elm-live src/Main.elm --open -- --output=elm.js (will start server on localhost)

-- MAIN

main : Program () Model Msg
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
  { key : Nav.Key
  , url : Url.Url
  , page : Page
  , search : Search.Model
  , carousel : Carousel.Model
  }

type Page 
  = NotFound
  | Gallery Gallery.Model
  | Forum
  | Profile
  --under here SignUp (SignUp.Model, Cmd SignUp.Msg)
  | SignUp SignUp.Model
  | SignIn SignIn.Model
  | Upload Upload.Model


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ({ key = key
    , url = url
    , page = NotFound
    , search = Search.init
    , carousel = Carousel.init
    }, Cmd.none)
    

type Msg
  = UrlRequest Browser.UrlRequest
  | UrlChange Url.Url
  | GalleryMsg Gallery.Msg  --converter types
  | SignUpMsg SignUp.Msg
  | SignInMsg SignIn.Msg
  | UploadMsg Upload.Msg
  | UpdateSearch Search.Msg
  | UpdateCarousel Carousel.Msg

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
      stepUrl url model
      --( { model | url = url}
      --, Cmd.none
      --)
    UpdateSearch mesg -> 
       ({ model | search = Search.update mesg model.search }, Cmd.none)
    UpdateCarousel mesg -> 
       ({ model | carousel = Carousel.update mesg model.carousel }, Cmd.none)
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
          ({model | page = SignIn (SignIn.update mesg signin)}, Cmd.none)
        _ -> (model, Cmd.none)
    GalleryMsg mesg ->
      case model.page of
        Gallery gallery -> stepGallery model (Gallery.update mesg gallery)
        _ -> ( model, Cmd.none )
    UploadMsg mesg ->
      case model.page of
        Upload upload -> stepUpload model (Upload.update mesg upload)
        _ -> ( model, Cmd.none )


stepUpload : Model -> (Upload.Model, Cmd Upload.Msg) -> (Model, Cmd Msg)
stepUpload model ( upload, cmd) = 
  ({ model | page = Upload upload }, Cmd.map UploadMsg cmd)

stepSignUp : Model -> (SignUp.Model, Cmd SignUp.Msg) -> (Model, Cmd Msg)
stepSignUp model (signup, cmd) =
  ({ model | page = SignUp signup }, Cmd.map SignUpMsg cmd)

stepSignIn : Model -> (SignIn.Model, Cmd SignIn.Msg) -> (Model, Cmd Msg)
stepSignIn model (signin, cmd) = 
  ({ model | page = SignIn signin }, Cmd.map SignInMsg cmd)

stepGallery : Model -> (Gallery.Model, Cmd Gallery.Msg) -> (Model, Cmd Msg)
stepGallery model (gallery, cmd) = 
  ({ model | page = Gallery gallery } , Cmd.map GalleryMsg cmd)

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  if model.page == NotFound
  then
    Carousel.subscriptions model.carousel |> Sub.map UpdateCarousel
  else
    Sub.none


-- VIEW


view : Model -> Browser.Document Msg
view model =
  case model.page of
    NotFound ->
      { title = "Elm Web Application"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
        viewHeader model
        , viewBody model
        , viewFooter
        ]
      }
    Gallery gallery ->
      { title = "Gallery"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
        viewHeader model
        , Gallery.view gallery |> Html.map GalleryMsg
        , viewFooter        
        ]
      }
    Forum ->
      { title = "Forum"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
        viewHeader model
        , viewBody model
        , viewFooter
        ]
      }
    Profile ->
      { title = "Profile"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
        viewHeader model
        --, viewBody model
        , viewFooter
        ]
      }
    SignUp signup ->
      { title = "Sign up"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
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
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
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

first: (SignUp.Model, Cmd SignUp.Msg) -> SignUp.Model
first model =
  Tuple.first model

viewImage : String -> Int -> Int -> Html msg
viewImage path w h =
  img[src path, width w, height h] []

viewHeader: Model -> Html Msg
viewHeader model =
    div [] [
    {--
    div [class "header"]
    [
        h1 [] [
          div[style "display" "inline"
              , style "margin-right" "10px"]
          [
          viewImage "../src/img/Elm_logo.svg.png" 70 70
          ]
          , a [ href "/" ] [ text "Elm prototype" ]--}
          viewNav model{--
        ]
        , Search.view model.search |> Html.map UpdateSearch
        , div [class "login"][
          a [ href "/sign_up" ] [ text "Sign up" ]
          , text " "
          , a [ href "/sign_in" ] [ text "Sign in" ]
        ]--}
    ]

viewNav: Model -> Html Msg
viewNav model = 
  div [ class "navbar navbar-inverse navbar-fixed-top" ]
    [ 
      div [ class "container-fluid"][
        div [ class "navbar-header"][
          div [ class "navbar-brand"][ 
            viewImage "../src/img/Elm_logo.svg.png" 35 35 
            ]
        ]
        , ul [ class "nav navbar-nav"][
            li [] [ a [ href "/" ] [ text "Home"] ]
            , li [] [ a [ href "/gallery" ] [ text "Gallery" ] ]
            , li [] [ a [href "/upload" ] [text "Upload Image"] ]
            , li [] [ a [href "/users" ] [text "Users"] ]
            , li [] [ Search.view model.search |> Html.map UpdateSearch ]
            --, li [] [ a [ href "/forum" ] [ text "Forum" ] ]
            --, li [] [ a [ href "/profile" ] [ text "Profile" ] ]
        ]
        
        , ul [ class "nav navbar-nav navbar-right" ][
            li [] [ a [ href "/sign_in"] [ span [class "glyphicon glyphicon-user"][], text " Sign In"] ]
            , li [] [ a [ href "/sign_up"] [ span [class "glyphicon glyphicon-user"][], text " Sign Up"] ]
          ]
        
        {--
        , ul [ style "margin-top" "7px", class "nav navbar-nav navbar-right" ][
             li [] [ img [ class "avatar", src "../src/img/Elm_logo.svg.png", width 35, height 35 ] [] ] 
             , li [ style "margin-top" "7px"
                  , style "margin-left" "5px" ] 
                  [ span [ class "glyphicon glyphicon-menu-hamburger"
                         , style "color" "grey" ] [] 
             ]
        ] --}
      ] 
    ]

viewBody: Model -> Html Msg
viewBody model =
  div [ ] [
    div [ class "container-fluid text-center", style "background-color" " #1abc9c", style "height" "800px" ][
      h1 [ style "margin-top" "100px", style "color" "white" ] [ text "Welcome to my website" ]
    ]
  {--
    div [ class "jumbotron"
          , style "height" "1000px" 
          , style "text-align" "center"
          , style "padding-top" "100px" 
          , style "width" "100%" ][
            h1 [][ text "Welcome to my website"]
            , p [] [ text "Powered by Elm. This website was created as a project for my bachelor's thesis" ]
            , div [ class "carousel" ][ Carousel.view model.carousel |> Html.map UpdateCarousel ]
    ]
    --}
  ]

--viewSignUpForm: Model -> Html Msg
--viewBody model =

viewFooter: Html Msg
viewFooter =
  div [style "background-color" "white"
      , style "height" "200px"
      , style "text-align" "center"
      , style "color" "white"
      , style "padding-top" "100px"
      , style "background-color" "#2f2f2f"
      , class "container-fluid text-center"]
  [ text "© 2019 Juraj Bedej   "
  , a [ href "https://github.com/jaruji?tab=repositories"] [ text "Github"]
  ]

--Router

stepUrl : Url.Url -> Model -> (Model, Cmd Msg)
stepUrl url model =
  let
    parser =
      oneOf   --rerouting based on url change!
        [ route (s "gallery")
            ( stepGallery model (Gallery.init)
            )
          , route (s "forum")
            ( stepGallery model (Gallery.init)
            )
          , route (s "profile")
            ( stepGallery model (Gallery.init)
            )
          , route (s "sign_up")
            ( stepSignUp model (SignUp.init)
            )
          , route (s "sign_in")
            ( stepSignIn model (SignIn.init)
            )
          , route (s "upload")
            ( stepUpload model (Upload.init)
            )
        ]
  in 
  case Parser.parse parser url of
    Just urll ->
      urll

    Nothing ->
      ({model | page = NotFound}, Cmd.none)

route : Parser a b -> a -> Parser (b -> c) c
route parser handler =
  Parser.map handler parser