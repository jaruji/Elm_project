module Pages.Gallery exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, field, string)
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import FeatherIcons as Icons
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
    , downvotes: Int
    , views: Int
  }

type Status
    = Loading
    | Failure
    | Success (List ImagePreview)


type Msg
    = Response (Result Http.Error (List ImagePreview))
    | SortNewest
    | SortPopular
    | SortTop



init :  Maybe User.Model -> Nav.Key -> (Model, Cmd Msg)
init user key =
    ( Model Loading, post "title" 1)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Response response ->
            case response of
                Ok imageUrl ->
                    ({ model | status = Success imageUrl }, Cmd.none )

                Err _ ->
                    ({ model | status = Failure }, Cmd.none )

        SortNewest ->
          ({ model | status = Loading }, post "uploadedAt" -1)

        SortPopular ->
          ({ model | status = Loading }, post "views" -1)

        SortTop ->
          ({ model | status = Loading }, post "upvotes" -1)


view : Model -> Html Msg
view model =
  div[][
    h1[][ text "Image Gallery" ]
    , div [ class "help-block" ][ text "Browse images uploaded by our users" ]
    , hr [ style "width" "80%" ][]
    , div [ class "alert alert-info"
    , style "width" "80%" 
    , style "margin" "auto" ][
      text "Sort by: "
      , button[ onClick SortNewest
      , style "margin-right" "10px"
      , style "background" "Transparent"
      , style "outline" "none"
      , style "border" "none" ][ text "Newest" ]
      , button[ onClick SortPopular
      , style "margin-right" "10px"
      , style "background" "Transparent"
      , style "outline" "none"
      , style "border" "none" ] [ text "Most Popular" ]
      , button[ onClick SortTop
      , style "background" "Transparent"
      , style "outline" "none"
      , style "border" "none" ] [ text "Top Rated"]
    ]
    , case model.status of
        Loading ->
          div [ style "margin-top" "50px" ] [
            h3 [] [ text "Fetching data from the server" ]
            , Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
          ]

        Failure ->
          div [ class "alert alert-danger"
          , style "margin-top" "50px"
          , style "width" "60%"
          , style "margin" "auto"
          , style "margin-top" "50px" ] [
            h4 [] [ text "Gallery failed to load" ]
          ]

        Success images ->
          div[][
            div [ class "panel panel-default"
            , style "border" "none" ]
               (List.map showPreview images)
          ]
  ]

viewEye: String -> Html msg
viewEye count =
  button[ style "color" "gray"
  , style "background" "Transparent"
  , style "outline" "none"
  , style "border" "none"
  , style "opacity" "0.8" ][
    Icons.eye |> Icons.withSize 20 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] 
    , span [ style "margin-left" "10px" ][ text count ]
  ]

viewMessages: Html msg
viewMessages =
     Icons.messageSquare |> Icons.withSize 20 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] 

viewThumbsUp: Html msg
viewThumbsUp =
     Icons.thumbsUp |> Icons.withSize 20 |> Icons.withStrokeWidth 3 |> Icons.toHtml [] 

showPreview: ImagePreview -> Html Msg
showPreview image =
  div [ style "display" "inline-block"
  , class "jumbotron"
  , style "background-color" "white" ][
    a[ href ("/post/" ++ image.id) 
    , class "preview" ][
      div [ style "margin-top" "-40px"][
        h4 [][
          text image.title 
        ]
        , div [ class "help-block" 
        , style "margin-top" "-10px" ][ text ("by "), a [ href "/profile/jaruji" ] [ text "jaruji"] ]
        , img[src image.url
        , height 400
        , class "preview thumbnail"
        , width 300
        , style "object-fit" "cover"
        , style "margin" "auto 10px" ][
          text "Could not display image" 
        ]
      ]
    ]   
    {--
    , div [ style "margin-top" "10px"
    , style "margin" "auto" ] [
      div [ class "caption" ][ text "0 comments" ]
    --}
    {--
      span [ style "float" "left", style "margin-left" "60px" ][ viewEye (String.fromInt image.views) ]
      , span [][ viewMessages, text "0" ]
      , span [ style "float" "right", style "margin-right" "60px" ][ viewThumbsUp, text (String.fromInt (image.upvotes - image.downvotes)) ]
    --}
    --]
    --, hr [][]
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

encodeQuery: String -> Int -> Encode.Value
encodeQuery query order =
  Encode.object[(query, Encode.int order)]

post : String -> Int -> Cmd Msg
post query order =
    Http.post
      { 
        url = Server.url ++ "/images/get"
        , body = Http.jsonBody <| encodeQuery query order
        , expect = Http.expectJson Response (Decode.list imagePreviewDecoder)
      }