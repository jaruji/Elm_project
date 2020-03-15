module Pages.SignIn exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick, onMouseEnter)
import Http
import Json.Encode as Encode exposing (..)
import Json.Decode as Decode exposing (list, field, string)
import Loading as Loader
import Crypto.Hash as Crypto
import Session

-- MODEL


type alias Model =
  { name : String
  , password : String
  , warning : String
  , status : Status
  , serverResponse : String
  , key : Nav.Key
  }

init : Nav.Key -> (Model, Cmd Msg, Session.UpdateSession)
init key =
  (Model "" "" "" Loading "" key, Cmd.none, Session.NoUpdate)



-- UPDATE


type Msg
  = Name String
  | Password String
  | Submit
  | Response (Result Http.Error String)

{--
type Session --session
  = Anonymous
  | LoggedIn
--}
 
type Status --status when logging in
  = Loading
  | Failure Http.Error
  | Success String



update : Session.Session -> Msg -> Model -> ( Model, Cmd Msg, Session.UpdateSession )
update session msg model =
  case msg of
    Name name ->
      ( { model | name = name }, Cmd.none, Session.NoUpdate )

    Password password ->
      ( { model | password = password }, Cmd.none, Session.NoUpdate )

    Submit ->
      if model.name == "" then
        ( {model | warning = "Enter your username"}, Cmd.none, Session.NoUpdate )
      else if model.password == "" then
        ( {model | warning = "Enter your password"}, Cmd.none, Session.NoUpdate )
      else
        ( {model | status = Loading,  warning = "Loading"}, post model, Session.NoUpdate )  --Nav.pushUrl model.key ("/"))

    Response response ->
      case response of
        Ok string ->
          case string of
            "OK" ->
              ( {model | status = Success string, serverResponse = string }, Nav.pushUrl model.key ("/"), Session.LogIn model.name )
            _ ->
              ( { model | status = Success string, serverResponse = string }, Cmd.none, Session.NoUpdate )
        Err log ->
          ( {model | status = Failure log}, Cmd.none, Session.NoUpdate )

-- VIEW


view : Model -> Html Msg
view model =
  div [ class "form-horizontal", id "form", style "margin" "auto", style "width" "75%" ]
  [ 
    h2 [ class "text-center" ] [ text "Log In with an existing account" ]
    , div [ class "help-block", style "padding-bottom" "10px" ] [
      text "Don't have an account?"
      , a [ href "/sign_up", style "margin-left" "5px" ] [ text "Sign Up" ]
    ]
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ] [
          case model.warning of
            "Enter your username" ->
              div[ class "form-group has-error has-feedback" ][
                label [ for "username" ] [ text "Username or E-mail:" ]
                , input [ id "username", type_ "text", class "form-control", Html.Attributes.value model.name, onInput Name ] []
                , span [ class "glyphicon glyphicon-remove form-control-feedback" ][]
              ]
            _ ->
              div[][
                label [ for "username" ] [ text "Username or E-mail:" ]
                , input [ id "username", type_ "text", class "form-control", Html.Attributes.value model.name, onInput Name ] []
              ]
        ]
    ]
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ] [
          case model.warning of
            "Enter your password" ->
              div[ class "form-group has-error has-feedback" ][
                label [ for "password" ] [ text "Password:" ]
                , input [ id "password", type_ "password", class "form-control", Html.Attributes.value model.password, onInput Password ] []
                , span [ class "glyphicon glyphicon-remove form-control-feedback" ][]
              ]
            _ ->
              div[][
                label [ for "password" ] [ text "Password:" ]
                , input [ id "password", type_ "password", class "form-control", Html.Attributes.value model.password, onInput Password ] []
              ]
        ]
    ]
    , button[ class "btn btn-primary", style "margin" "auto", onClick Submit ][ text "Sign in" ]
    , case model.warning of
        "Loading" ->
          case model.status of
            Loading ->
              div[ class "alert alert-info", style "margin-top" "15px" ] [
                Loader.render Loader.Circle Loader.defaultConfig Loader.On
                ,text model.warning
              ]
            Failure err ->
              div[ class "alert alert-warning", style "margin-top" "15px" ] [
                text "Error"
              ]
            Success _ ->
              --ak sa dostaneme do tejto vetvy bez presmerovania, bolo zadane zle meno/heslo 
              div [ class "alert alert-warning", style "margin-top" "15px" ] [
                text "Incorrect username or password"
              ]
        "" ->
          div [] []
        _ ->
          div[ class "alert alert-warning", style "margin-top" "15px" ] [
            text model.warning
          ]
  ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  div[ class "form-group", style "width" "40%" ][
    label [] [ text p ]
    , input [ class "form-control", class "col-md-offset-2 col-md-8", type_ t, placeholder p, value v, onInput toMsg ] []
  ]

viewValidation : Model -> Html msg
viewValidation model =
  if model.password == model.name then
    div [ style "color" "green" ] [ text "OK" ]
  else
    div [ style "color" "red" ] [ text "Passwords do not match!" ]

accountEncoder : Model -> Encode.Value
accountEncoder model =
  Encode.object 
    [ ( "username", Encode.string model.name )
    , ( "password", Encode.string (Crypto.sha256 model.password) )
    ]

post : Model -> Cmd Msg
post model =
  Http.request
    { method = "POST"
    , headers = []
    , url = "http://localhost:3000/validate"
    --, url = "http://httpbin.org/post"
    , body = Http.jsonBody <| accountEncoder model 
    , expect = Http.expectJson Response (field "response" Decode.string)
    , timeout = Nothing
    , tracker = Nothing
    }
