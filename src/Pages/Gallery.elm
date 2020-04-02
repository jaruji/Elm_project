module Pages.Gallery exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, field, string)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import User
import Image
import Server

--https://package.elm-lang.org/packages/FabienHenon/elm-infinite-scroll/latest/InfiniteScroll
--https://w3bits.com/labs/css-image-hover-zoom/ -make the gallery looks like this :)

type alias Model = 
  {
    status: Status
  }

type alias ImagePreview =
  {
    id: String
    , title: String
    , url: String
    , author: String
    , upvotes: Int
    , downotes: Int
    , views: Int
  }

type Status
    = Loading
    | Failure
    | Success (List ImagePreview)


type Msg
    = Response (Result Http.Error (List ImagePreview))



init :  Maybe User.Model -> Nav.Key -> (Model, Cmd Msg)
init user key =
    ( Model Loading, get )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Response response ->
            case response of
                Ok imageUrl ->
                    ({ model | status = Success imageUrl }, Cmd.none )

                Err _ ->
                    ({ model | status = Failure }, Cmd.none )


view : Model -> Html Msg
view model =
    case model.status of
        Loading ->
          div [ style "height" "400px", style "margin-top" "25%", style "text-align" "center" ] [
            h2 [] [ text "Fetching data from the server" ]
            , Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
          ]

        Failure ->
          div [ style "height" "400px", style "margin-top" "25%", style "text-align" "center" ] [
            h2 [] [ text "Gallery failed to load" ]
          ]

        Success images ->
          div[][
            h1[][ text "Image Gallery" ]
            , div [ class "help-block" ][ text "Browse images uploaded by our users" ]
            , hr [ style "width" "80%" ][]
            , div [ class "panel panel-default"
            , style "border" "none" ]
               (List.map showPreview images)
          ]

showPreview: ImagePreview -> Html Msg
showPreview image =
  a[ href ""
  , style "display" "inline-block"
  , class "preview" ][
    h4 [][ text image.title ]
    , img[src image.url
    , height 400
    , width 400
    , style "object-fit" "cover"
    , style "margin" "auto 10px" ][ text "Could not display image" ]
    , hr [][]
  ]


imagePreviewDecoder: Decode.Decoder ImagePreview
imagePreviewDecoder =
    Decode.succeed ImagePreview
        |> required "id" Decode.string
        |> required "title" Decode.string
        |> required "file" Decode.string
        |> optional "author" Decode.string "Anonymous"
        |> required "upvotes" Decode.int
        |> required "downvotes" Decode.int
        |> required "views" Decode.int

get : Cmd Msg
get =
    Http.get
      { 
        url = Server.url ++ "/images/get"
        , expect = Http.expectJson Response (Decode.list imagePreviewDecoder)
      }