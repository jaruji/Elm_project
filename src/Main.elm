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
import Pages.Home as Home
import Components.SearchBar as Search
import Components.Carousel as Carousel
import Session
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
  , search : ( Search.Model, Cmd Search.Msg )
  , carousel : Carousel.Model
  , state : State
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
  | Home Home.Model


type State
  =  Ready Session.Session

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ({ key = key
    , url = url
    , page = NotFound
    , search = Search.init key
    , carousel = Carousel.init
    , state = Ready Session.init
    }, Nav.pushUrl key ("/"))
    

type Msg
  = UrlRequest Browser.UrlRequest
  | UrlChange Url.Url
  | GalleryMsg Gallery.Msg  --converter types
  | SignUpMsg SignUp.Msg
  | SignInMsg SignIn.Msg
  | HomeMsg Home.Msg
  | UploadMsg Upload.Msg
  | UpdateSearch Search.Msg
  | UpdateCarousel Carousel.Msg
  | LogOut

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

    LogOut ->
      ( { model | state = Ready Session.init }, Nav.pushUrl model.key ("/") )
    
    UpdateSearch mesg -> 
       --({ model | search = Search.update mesg (Search.getModel model.search) }, Cmd.none)
       stepSearch model (Search.update mesg (Search.getModel model.search))

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
          case model.state of
            Ready session ->
              stepSignIn model (SignIn.update session mesg signin)
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
  if model.page == NotFound
  then
    Carousel.subscriptions model.carousel |> Sub.map UpdateCarousel
  else
    Sub.none
  {--
  case model.page of
    Home home ->
      Carousel.subscriptions home.carousel |> Sub.map UpdateCarousel
    _ ->
      Sub.none
  --}


-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.page of
      NotFound ->
        { title = "Not Found"
        , body = [
          viewHeader model
          , viewBody model
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
          , Gallery.view gallery |> Html.map GalleryMsg
          , viewFooter        
          ]
        }
      Forum ->
        { title = "Forum"
        , body = [
          viewHeader model
          , viewBody model
          , viewFooter
          ]
        }
      Profile ->
        { title = "Profile"
        , body = [
          viewHeader model
          --, viewBody model
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

viewImage : String -> Int -> Int -> Html msg
viewImage path w h =
  img[src path, width w, height h] []

viewHeader: Model -> Html Msg
viewHeader model =
    div [] [
        viewNav model
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
            , li [] [ a [ href "/upload" ] [ text "Upload Image"] ]
            , li [] [ a [ href "/users" ] [ text "Users"] ]
            , li [] [ Search.view (Search.getModel model.search) |> Html.map UpdateSearch ]
            --, li [] [ a [ href "/forum" ] [ text "Forum" ] ]
            --, li [] [ a [ href "/profile" ] [ text "Profile" ] ]
        ]
        
        , case model.state of
          Ready session ->
            case session.username of
              Nothing ->
                ul [ class "nav navbar-nav navbar-right" ][
                  li [] [ a [ href "/sign_in" ] [ span [class "glyphicon glyphicon-user"][], text " Sign In"] ]
                  , li [] [ a [ href "/sign_up" ] [ span [class "glyphicon glyphicon-user"][], text " Sign Up"] ]
                ]
              Just username ->
               ul [ class "nav navbar-nav navbar-right" ] [
                li [] [ text username ]
                , li [] [ button [ class "btn btn-primary", onClick LogOut ] [ text "Log Out" ] ]
               ]
      ] 
    ]

viewBody: Model -> Html Msg
viewBody model =
  div [ style "height" "800px", style "margin-top" "25%", style "text-align" "center" ] [
    h2 [] [ text "Oops! This page doesn't exist" ]
    , viewSession model.state
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
  [ text "© 2020 Juraj Bedej"
  , br [][]
  , a [ href "https://github.com/jaruji?tab=repositories"] [ text "Source"]
  , br [][]
  , a [ href "/contact" ] [ text "Contact me" ]
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
          , route (s "profile")
            ( stepGallery model (Gallery.init)
            )
          , route (s "sign_up")
            ( stepSignUp model (SignUp.init model.key)
            )
          , route (s "sign_in")
            (
              case model.state of
                Ready session ->
                  stepSignIn model ( SignIn.init model.key  )
            )
          , route (s "upload")
            ( stepUpload model (Upload.init)
            )
          , route (top)
            ( stepHome model (Home.init model.key)
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

viewSession: State -> Html Msg
viewSession state =
  case state of
    Ready session ->
      case session.username of
        Just username ->
          text username
        Nothing ->
          text "Not logged in..."