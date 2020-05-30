module Pages.SignUp exposing (..)

import Browser
import Browser.Navigation as Nav
import Browser.Dom as Dom
import Task
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http exposing (..)
import Email
import Json.Decode as Decode exposing (list, field, string)
import Json.Encode as Encode exposing (..)
import Loading as Loader
import Crypto.Hash as Crypto
import Server

{--
  Page used for registration of user. Needs to handle errors and also dynamically check if
  username or email are taken. If they are, the input will change it's border color to indicate
  that the value is not valid. You wont be allowed to register until all input are valid, meaning
  their border color is green.
--}

type alias Model =
  { name : String
  , password : String
  , passwordAgain : String
  , email : String
  , warning : String
  , status : Status
  , verification: String
  , key : Nav.Key
  , errorUsername: Bool
  , errorEmail: Bool
  }

init : (Nav.Key) -> (Model, Cmd Msg)
init key =
  (Model "" "" "" "" "" Loading "" key False False, Task.perform (\_ -> Empty) (Dom.setViewport 0 0))

type Msg
  = Name String
  | Password String
  | PasswordAgain String
  | Email String
  | Warning String
  | Verification String
  | Submit
  | Response (Result Http.Error String)
  | UsernameResponse (Result Http.Error String)
  | EmailResponse (Result Http.Error String)
  | Empty

type Status
  = Loading
  | Failure Http.Error
  | Success String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Empty ->
      (model, Cmd.none)

    Name name ->
      ({ model | name = name }, checkUsername name)

    Password password ->
      ({ model | password = password }, Cmd.none)

    PasswordAgain password ->
      ({ model | passwordAgain = password }, Cmd.none)
  
    Email email ->
      ({ model | email = email }, checkEmail email)

    Warning error ->
      ({ model | warning = error }, Cmd.none)

    Submit ->
      --handle all possible cases of errors when sign up button is pressed
      if model.name == "" then
        ({model | warning = "Enter your username"}, Cmd.none)
      else if validateUsername model.name == False then
        ({model | warning = "Username must be longer"}, Cmd.none)
      else if model.errorUsername == True then
        ({model | warning = "Username is already taken"}, Cmd.none)
      else if validateEmail model.email == Nothing then
        ({model | warning = "Enter a valid e-mail address"}, Cmd.none)
      else if model.errorEmail == True then
        ({model | warning = "E-mail is already taken"}, Cmd.none)
      else if model.password == "" then
        ({model | warning = "Enter your password"}, Cmd.none)
      else if len model.password == False then
        ({model | warning = "Password is too short"}, Cmd.none)
      else if model.passwordAgain == "" then
        ({model | warning = "Enter your password again"}, Cmd.none)
      else if validatePassword model.password model.passwordAgain == False then
        ({model | warning = "Passwords do not match"}, Cmd.none)
      else
        ({model | status = Loading,  warning = "Loading"}, post model)
   
    Response response ->
      case response of
        Ok string ->
          ( {model | status = Success string}, Nav.pushUrl model.key ("/sign_in") )
        Err log ->
          ( {model | status = Failure log}, Cmd.none )

    UsernameResponse response ->
      case response of
        Ok string ->
          case string of 
            "OK" -> 
              ({model | errorUsername = True}, Cmd.none)
            _ ->
              ({model | errorUsername = False}, Cmd.none)

        Err log ->
          ({model | status = Failure log}, Cmd.none)

    EmailResponse response ->
      case response of
        Ok string ->
          case string of
            "OK" -> 
              ({model | errorEmail = True}, Cmd.none)
            _ ->
              ({model | errorEmail = False}, Cmd.none)

        Err log ->
          ({model | status = Failure log}, Cmd.none)

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
          case model.errorUsername of
            True -> 
              div[][ 
                div[ class "form-group has-error has-feedback" ][
                  label [ for "username" ] [ text "Username:" ]
                  , input [ id "username", type_ "text", class "form-control", Html.Attributes.value model.name, onInput Name ] []
                  , span [ class "glyphicon glyphicon-remove form-control-feedback" ][]
                ]
              ]
            False ->
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
        case model.errorEmail of
          True -> 
            div[ class "form-group has-error has-feedback" ][
                  label [ for "email" ] [ text "E-mail:" ]
                  , input [ id "email", type_ "email", class "form-control", Html.Attributes.value model.email, onInput Email ] []
                  , span [ class "glyphicon glyphicon-remove form-control-feedback" ][]
                ]
          False ->
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

usernameEncoder : String -> Encode.Value
usernameEncoder name =
  Encode.object
  [ ( "username", Encode.string name )
  ]

checkUsername: String -> Cmd Msg
checkUsername username =
    Http.post {
      url = Server.url ++ "/account/validate"
      , body = Http.jsonBody <| usernameEncoder username
      , expect = Http.expectJson UsernameResponse (field "response" Decode.string)
    }

validateUsername : String -> Bool
validateUsername name =  
  if name /= "" then
    True
  else
    False

emailEncoder : String -> Encode.Value
emailEncoder email =
  Encode.object
  [ ( "email", Encode.string email )
  ]

checkEmail: String -> Cmd Msg
checkEmail email =
    Http.post {
      url = Server.url ++ "/account/validate"
      , body = Http.jsonBody <| emailEncoder email
      , expect = Http.expectJson EmailResponse (field "response" Decode.string)
    }

validateEmail : String -> Maybe Email.Email
validateEmail email =
    Email.fromString email

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
    , headers = []
    , url = Server.url ++ "/account/sign_up"
    , body = Http.jsonBody <| userEncoder model 
    , expect = Http.expectJson Response (field "response" Decode.string)
    , timeout = Nothing
    , tracker = Nothing
    }

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

toString : Http.Error -> String
toString err =
    --display type of error as string
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
