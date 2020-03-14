module Pages.SignUp exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http exposing (..)
import Email
import Json.Decode as Decode exposing (list, field, string)
import Json.Encode as Encode exposing (..)
import Loading as Loader
import Crypto.Hash as Crypto



-- MODEL


type alias Model =
  { name : String
  , password : String
  , passwordAgain : String
  , email : String
  --, submit : Bool
  , warning : String
  , status : Status
  , verification: String
  , key : Nav.Key
  }


init : (Nav.Key) -> (Model, Cmd Msg)
init key =
  (Model "" "" "" "" "" Loading "" key, Cmd.none)



-- UPDATE


type Msg
  = Name String
  | Password String
  | PasswordAgain String
  | Email String
  | Warning String
  | Verification String
  | Submit
  | Response (Result Http.Error String)

type Status
  = Loading
  | Failure Http.Error
  | Success String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Name name ->
      ({ model | name = name }, Cmd.none)

    Password password ->
      ({ model | password = password }, Cmd.none)

    PasswordAgain password ->
      ({ model | passwordAgain = password }, Cmd.none)
  
    Email email ->
      ({ model | email = email }, Cmd.none)

    Warning error ->
      ({ model | warning = error }, Cmd.none)

    Submit ->
      if model.name == "" then
        ({model | warning = "Enter your username"}, Cmd.none)
      else if validateUsername model.name == False then
        ({model | warning = "Username is already used"}, Cmd.none)
      else if validateEmail model.email == Nothing then
        ({model | warning = "Enter a valid e-mail address"}, Cmd.none)
      else if model.password == "" then
        ({model | warning = "Enter your password"}, Cmd.none)
      else if len model.password == False then
        ({model | warning = "Password is too short"}, Cmd.none)
      else if model.passwordAgain == "" then
        ({model | warning = "Enter your password again"}, Cmd.none)
      else if validatePassword model.password model.passwordAgain == False then
        ({model | warning = "Passwords do not match"}, Cmd.none)
      else
        ({model | status = Loading,  warning = "Loading"}, Cmd.batch [post model,  Nav.pushUrl model.key ("/sign_in")] )
   
    Response response ->
      case response of
        Ok string ->
          ( {model | status = Success string}, Cmd.none )
        Err log ->
          ( {model | status = Failure log}, Cmd.none )

    Verification code ->
      ( {model | verification = code}, Cmd.none )
-- VIEW


view : Model -> Html Msg
view model =
  div [ class "form-horizontal", id "form", style "margin" "auto", style "width" "75%" ]
  [ 
    h2 [ class "text-center" ] [ text "Create an Account" ]
    , div [ class "help-block", style "padding-bottom" "10px" ] [
      text "Already have an account?"
      , a [ href "/sign_in", style "margin-left" "5px" ] [ text "Sign In" ]
    ]
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ] [
          case validateUsername model.name of
            True ->
              div[][ 
                div[ class "form-group has-success has-feedback" ][
                label [ for "username" ] [ text "Username:" ]
                , input [ id "username", type_ "text", class "form-control", Html.Attributes.value model.name, onInput Name ] []
                , span [ class "glyphicon glyphicon-ok form-control-feedback" ][]
                ]
              ]
            False ->
              div[][ 
                div[ class "form-group has-error has-feedback" ][
                  label [ for "username" ] [ text "Username:" ]
                  , input [ id "username", type_ "text", class "form-control", Html.Attributes.value model.name, onInput Name ] []
                  , span [ class "glyphicon glyphicon-remove form-control-feedback" ][]
                ]
              ]
        ]
    ]
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ] [
          case validateEmail model.email of
            Just _ ->
              div[ class "form-group has-success has-feedback" ][
                label [ for "email" ] [ text "E-mail:" ]
                , input [ id "email", type_ "email", class "form-control", Html.Attributes.value model.email, onInput Email ] []
                , span [ class "glyphicon glyphicon-ok form-control-feedback" ][]
              ]
            Nothing ->
              div[ class "form-group has-error has-feedback" ][
                label [ for "email" ] [ text "E-mail:" ]
                , input [ id "email", type_ "email", class "form-control", Html.Attributes.value model.email, onInput Email ] []
                , span [ class "glyphicon glyphicon-remove form-control-feedback" ][]
              ]
        ]
    ]
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ] [
          case len model.password of
            False ->
              div[ class "form-group has-error has-feedback" ][
                label [ for "password" ] [ text "Password:" ]
                , input [ id "password", type_ "password", class "form-control", Html.Attributes.value model.password, onInput Password ] []
                , span [ class "glyphicon glyphicon-remove form-control-feedback" ][]
              ]
            True ->
              div[ class "form-group has-success has-feedback" ][
                label [ for "password" ] [ text "Password:" ]
                , input [ id "password", type_ "password", class "form-control", Html.Attributes.value model.password, onInput Password ] []
                , span [ class "glyphicon glyphicon-ok form-control-feedback" ][]
              ]
        ]
    ]
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ] [
          case validatePassword model.password model.passwordAgain of
            False ->
              div[ class "form-group has-error has-feedback" ][
                label [ for "passwordAgain" ] [ text "Password again:" ]
                , input [ id "passwordAgain", type_ "password", class "form-control", Html.Attributes.value model.passwordAgain, onInput PasswordAgain ] []
                , span [ class "glyphicon glyphicon-remove form-control-feedback" ][]
              ]
            True ->
              div[ class "form-group has-success has-feedback" ][
                label [ for "passwordAgain" ] [ text "Password again:" ]
                , input [ id "passwordAgain", type_ "password", class "form-control", Html.Attributes.value model.passwordAgain, onInput PasswordAgain ] []
                , span [ class "glyphicon glyphicon-ok form-control-feedback" ][]
              ]
        ]
    ]
    , button[ class "btn btn-primary", style "margin" "auto", onClick Submit ][ 
      text "Sign Up"
      , div [] [ 
      ]
    ]
    , case model.warning of
        "" ->
          div[][]
        "Loading" ->
          case model.status of
            Loading ->
              div[ class "alert alert-info", style "margin-top" "15px" ] [
                Loader.render Loader.Circle Loader.defaultConfig Loader.On
                ,text model.warning
              ]
            Failure err ->
              div[ class "alert alert-warning", style "margin-top" "15px" ] [
                text (toString err)
              ]
            Success _ ->
              div[ class "alert alert-success", style "margin-top" "15px" ] [
                --viewVerify model
              ]
        _ ->
          div[ class "alert alert-warning", style "margin-top" "15px" ] [
            text model.warning
          ]
  ]

viewVerify: Model -> Html Msg
viewVerify model =
  div [ class "form-horizontal fade in", id "form", style "margin" "auto", style "width" "75%" ] [
    h2 [ class "text-center" ] [ text "Complete your registration" ]
    , div [ class "help-block" ] [ text ("We sent an e-mail to " ++ model.email) ]
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ] [
          div[][ 
                div[ class "form-group" ][
                  label [ for "verify" ] [ text "Enter the received code:" ]
                  , input [ id "verify", type_ "text", class "form-control", Html.Attributes.value model.verification, onInput Verification ] []
                  , button [ class "btn btn-primary", style "margin-top" "10px" ][ text "Verify" ]
                ]
          ]
        ]
    ]
  ]

resetButton : Model -> Model
resetButton model =
  { model | status = Loading }

len : String -> Bool
len pass =
  if String.length pass > 6 then
    True
  else
    False

validatePassword : String -> String -> Bool
validatePassword pass passAgain =
  if pass == passAgain && passAgain /= "" then
    True
  else
    False

validateEmail : String -> Maybe Email.Email
validateEmail email =
    Email.fromString email


usernameEncoder : String -> Encode.Value
usernameEncoder name =
  Encode.object
  [ ( "username", Encode.string name )
  ]

emailEncoder : String -> Encode.Value
emailEncoder email =
  Encode.object
  [ ( "email", Encode.string email )
  ]

validateUsername : String -> Bool
validateUsername username = 
  if username /= "" then
    True
  else
    False

userEncoder : Model -> Encode.Value
userEncoder model =
  Encode.object 
  --send and stored HASHED password on server (security). During login, all attempts will
  --also be hashed and compared to the account password stored on the server
    [ ( "username", Encode.string model.name )
    , ( "password", Encode.string (Crypto.sha256 model.password) )
    , ( "email", Encode.string model.email )
    ]

post : Model -> Cmd Msg
post model = 
  Http.request
    { method = "POST"
    --, headers = [ Http.header "Access-Control-Allow-Headers" "X-Requested-With", Http.header "Access-Control-Allow-Origin" "*"]
    , headers = []
    , url = "http://localhost:3000/sign_up"
    --, url = "http://httpbin.org/post"
    , body = Http.jsonBody <| userEncoder model 
    , expect = Http.expectJson Response (field "response" Decode.string)
    , timeout = Nothing
    , tracker = Nothing
    }

  {--
  Http.post { url = "http://localhost:3000/sign_up"
            , body = Http.emptyBody
            --, body = Http.jsonBody <| userEncoder model 
            --, body = Http.stringBody "application/json" "Hello world"
            -- I actually dont get this trash, why does empty work but others dont?
            , expect = Http.expectJson Response (field "response" Decode.string)}
  --}

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

toString : Http.Error -> String
toString err =
--convert Http.Error type to String, used for debugging potential connection issues
    case err of
        Timeout ->
            "Timeout exceeded"

        NetworkError ->
            "Network error"

        BadUrl url ->
            "Bad url"

        BadStatus s -> 
          "Bad status"

        BadBody s ->
          "Bad body : " ++ s
