module Pages.SignUp exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Email
import Json.Decode exposing (list, string)




-- MODEL


type alias Model =
  { name : String
  , password : String
  , passwordAgain : String
  , email : String
  , warning : String
  }


init : (Model, Cmd Msg)
init =
  (Model "" "" "" "" "", Cmd.none)



-- UPDATE


type Msg
  = Name String
  | Password String
  | PasswordAgain String
  | Email String
  | Warning String
  | Submit
  | Loading
  | Result (Result Http.Error (List String))


update : Msg -> Model -> Model
update msg model =
  case msg of
    Name name ->
      { model | name = name }

    Password password ->
      { model | password = password }

    PasswordAgain password ->
      { model | passwordAgain = password }
  
    Email email ->
      { model | email = email }

    Warning error ->
      { model | warning = error }

    Submit ->
      if model.name == "" then
        {model | warning = "Enter your username"}
      else if validateUsername model.name == False then
        {model | warning = "Username is already used"}
      else if validateEmail model.email == Nothing then
        {model | warning = "Enter a valid e-mail address"}
      else if model.password == "" then
        {model | warning = "Enter your password"}
      else if len model.password == False then
        {model | warning = "Password is too short"}
      else if model.passwordAgain == "" then
        {model | warning = "Enter your password again"}
      else if validatePassword model.password model.passwordAgain == False then
        {model | warning = "Passwords do not match"}
      else
        (model)
        {--
        Http.post {url = "http://localhost:8000/sign_up"
                  , body = Http.emptyBody
                  , expect = Http.expectJson Result (list string)}
        --{model | warning = "Signing up..."
        {--, Http.post "http://localhost:8000/sign_up"--}
        --}

    Loading ->
      (model)

    Result _->
      (model)
-- VIEW


view : Model -> Html Msg
view model =
  div [ class "form-horizontal", id "form", style "margin" "auto", style "width" "75%" ]
  [ 
    h2 [ class "text-center" ] [ text "Create an Account" ]
    , div [ class "help-block", style "padding-bottom" "10px" ] [
      text "Password need to be at least 7 characters long"
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
          div[] [
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

validateEmail : String -> Maybe Email.Email
validateEmail email =
    Email.fromString email


validateUsername : String -> Bool
validateUsername username = 
  if username /= "" then
    True
  else
    False
