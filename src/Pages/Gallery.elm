module Pages.Gallery exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, field, string)
import Loading as Loader
import User

--https://package.elm-lang.org/packages/FabienHenon/elm-infinite-scroll/latest/InfiniteScroll
--https://w3bits.com/labs/css-image-hover-zoom/ -make the gallery looks like this :)

type alias Model = 
  {
    status: Status
  }

type Status
    = Loading
    | Failure
    | Success String


type Msg
    = GotResult (Result Http.Error String)


view : Model -> Html Msg
view model =
    case model.status of
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


get : Cmd Msg
get =
    Http.get
      { 
        url = "http://localhost:3000/img"
        , expect = Http.expectJson GotResult (field "file" string)
      }


init :  Maybe User.Model -> Nav.Key -> ( Model, Cmd Msg )
init user key =
    ( Model Loading, get )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResult result ->
            case result of
                Ok imageUrl ->
                    ({ model | status = Success imageUrl }, Cmd.none )

                Err _ ->
                    ({ model | status = Failure }, Cmd.none )
