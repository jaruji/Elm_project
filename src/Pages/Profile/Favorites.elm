module Pages.Profile.Favorites exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import User
import Server
import Http
import Image
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Json.Decode as Decode exposing (Decoder, field, string, int)

type alias Model =
  {
    user: User.Model
    , status: Status
  }

type Msg
  = Empty
  | Response (Result Http.Error (List Image.Preview))

type Status
  = Loading
  | Failure
  | Success (List Image.Preview)

getModel: (Model, Cmd Msg) -> Model
getModel (model, cmd) =
    model

init: User.Model -> (Model, Cmd Msg)
init user =
    (Model user Loading, Cmd.none)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Empty ->
            (model, Cmd.none)
        Response response ->
            case response of
                Ok images ->
                    ({ model | status = Success images }, Cmd.none)
                Err _ ->
                    ({ model | status = Failure }, Cmd.none)

view: Model -> Html Msg
view model =
    div[ class "container"
    , style "text-align" "center"
    , style "min-height" "500px" ][ 
        h3[][ text "My Favorites" ] 
        , div[ class "help-block" ][
            text "Here is the list of posts you favorited"
        ]
        , hr[][]
        , case model.status of
            Loading ->
                div [] [
                    Loader.render Loader.Circle Loader.defaultConfig Loader.On
                ]
            Failure ->
                div [ class "alert alert-warning"
                , style "width" "50%"
                , style "margin" "auto" ][
                    text "Connection error"
                ]
            Success images ->
                if List.length images == 0 then
                    div[ class "help-block" ][
                        text "You have no favorites"
                    ]
                else
                    div[](List.map Image.showTab images)
    ]

getFavs: String -> Cmd Msg
getFavs username =
    Http.get
    {
        url = Server.url ++ "/account/favorites" ++ "?username=" ++ username 
        , expect = Http.expectJson Response (Decode.list Image.decodePreview)
    }