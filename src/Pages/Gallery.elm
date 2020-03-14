module Pages.Gallery exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, field, string)
import Loading as Loader

--https://package.elm-lang.org/packages/FabienHenon/elm-infinite-scroll/latest/InfiniteScroll
--https://w3bits.com/labs/css-image-hover-zoom/ -make the gallery looks like this :)

type Model
    = Loading
    | Failure
    | Success String


view : Model -> Html Msg
view model =
    case model of
        Loading ->
          div[style "text-align" "center"
              , style "margin-top" "10%"
              , style "margin-bottom" "10%"][
            Loader.render Loader.Bars Loader.defaultConfig Loader.On
          ]

        Failure ->
          div[style "text-align" "center"
              , style "margin-top" "10%"
              , style "margin-bottom" "10%"][
            text "Image failed to load"
          ]

        Success imageUrl ->
          div [ style "text-align" "center"
              , style "margin-top" "10%"
              , style "margin-bottom" "10%"
              , class "image-box" ] [
            img [ src imageUrl, class "img-thumbnail", style "overflow" "hidden" ] []
          ]


fetchCatImageUrl : Cmd Msg
fetchCatImageUrl =
    Http.get
        { --url = "https://aws.random.cat/meow"
        url = "http://localhost:3000/img"
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
