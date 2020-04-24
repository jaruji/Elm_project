module Pages.Profile.Favorites exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import User
import Server
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Json.Decode as Decode exposing (Decoder, field, string, int)
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)
import Json.Encode as Encode exposing (..)


type alias Model =
  {
    user: User.Model
  }

type Msg
  = Empty

getModel: (Model, Cmd Msg) -> Model
getModel (model, cmd) =
    model

init: User.Model -> (Model, Cmd Msg)
init user =
    (Model user, Cmd.none)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Empty ->
            (model, Cmd.none)

view: Model -> Html Msg
view model =
    div[ class "container", style "text-align" "center" ][ 
        h3 [] [ text "My Favorites" ] 
    ]