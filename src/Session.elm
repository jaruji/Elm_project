module Session exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)

type alias Model =
  { 
    status: Msg ,
    username : String
  } 

type Msg
  = Anonymous
  | LoggedIn

init : Model
init =
  (Model Anonymous "")

login : Model -> String -> Model
login model name =
  { model | username = name, status = LoggedIn }

logout : Model -> Model
logout model =
  { model | username = "", status = Anonymous }


view : Model -> Html Msg
view model =
  div[] [
    case model.status of
      Anonymous ->
        text "Logged in as anonymous"
      LoggedIn ->
        text "Logged in as someone"
  ]