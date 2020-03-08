module Pages.Gallery exposing (..)

import Browser
import Html exposing (Html, img, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, field, string)


type Model
    = Loading
    | Failure
    | Success String


view : Model -> Html Msg
view model =
    case model of
        Loading ->
            text "loading..."

        Failure ->
            text "failed to fetch new cat image"

        Success imageUrl ->
            img [ src imageUrl ] []


fetchCatImageUrl : Cmd Msg
fetchCatImageUrl =
    Http.get
        { url = "https://aws.random.cat/meow"
        , expect = Http.expectJson GotResult (field "file" string)
        }


init : ( Model, Cmd Msg )
init  =
    ( Loading, fetchCatImageUrl )


type Msg
    = GotResult (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResult result ->
            case result of
                Ok imageUrl ->
                    ( Success imageUrl, Cmd.none )

                Err _ ->
                    ( Failure, Cmd.none )
