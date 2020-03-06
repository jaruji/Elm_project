module Pages.SignIn exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http




-- MODEL


type alias Model =
  { name : String
  , password : String
  , warning : String
  }

init : (Model, Cmd Msg)
init =
  (Model "" "" "", Cmd.none)



-- UPDATE


type Msg
  = Name String
  | Password String
  | Submit


update : Msg -> Model -> Model
update msg model =
  case msg of
    Name name ->
      { model | name = name }

    Password password ->
      { model | password = password }

    Submit ->
      if model.name == "" then
        {model | warning = "Enter your username"}
      else if model.password == "" then
        {model | warning = "Enter your password"}
      else
        {model | warning = "Incorrect username or password"}



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
    {--
    , case model.password of
        "cuck" ->
          a [ href "/sign_up" ] [ text "It works 5Head" ]
        _ ->
          a [ href "/sign_up", style "padding-left" "15px" ] [ text "Don't have an account?" ]
    --}
    , case model.warning of
        "" ->
          div[] [
          ]
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