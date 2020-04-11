module Image exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Decode.Extra as DecodeExtra
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import Server
import Image.Comment as Comment
import FeatherIcons as Icons
import Time
import TimeFormat

type alias Model =
  {
    title: String
    , url: String
    , id: String
    , description: String
    , author: String
    , tags: List String
    , points: Int
    , views: Int
    , uploaded: Time.Posix
  }

type alias Preview =
  {
    id: String
    , title: String
    , url: String
    , author: String
    , points: Int
    , views: Int
    , uploaded: Time.Posix
  }

type alias PreviewContainer =
  {
    total: Int
    , images: List Preview
  }

showPreview: Preview -> Html msg
showPreview image =
  div [ style "display" "inline-block"
  , class "jumbotron"
  , style "background-color" "white" ][
    div[][
      div [ style "margin-top" "-40px"][
        a [ href ("/post/" ++ image.id) ][
          img[ src image.url
          , attribute "draggable" "false"
          , height 400
          , class "preview"
          , width 400
          , style "object-fit" "cover"
          , style "margin" "auto 10px" ][
            text "Could not display image" 
          ]
        ]
        , div[ class "caption"
        , style "width" "400px"
        , style "border" "0.5px solid #F5F5F5"
        , style "height" "150px"
        , style "margin" "auto" ][
          h3 [][
            a [ class "preview", 
            href ("/post/" ++ image.id) ][
              text (trimString image.title) 
            ]
          ]
          {--
          , div [ class "help-block" 
          , style "margin-top" "-10px" ][ 
            text (TimeFormat.formatDate image.uploaded)
          ]--}
          , div [ class "help-block" 
          , style "margin-top" "-10px" ][
            text ("by ")
            , a [ href ("/profile/" ++ image.author)
            , class "preview" ][ text image.author ]
          ]
          , hr [][]
          , div [ style "opacity" "0.3" ][
            span [ class "col-sm-4"
            , title "Views" ][
              Icons.eye |> Icons.withSize 15 |> Icons.withStrokeWidth 2 |> Icons.toHtml [] 
              , b [ style "margin-left" "5px"
              , style "font-size" "15px" ][ text (String.fromInt image.views) ]
            ]
            , span [ class "col-sm-4"
            , title "Points" ][
              Icons.award |> Icons.withSize 15 |> Icons.withStrokeWidth 2 |> Icons.toHtml [] 
              , b [ style "margin-left" "5px"
              , style "font-size" "15px" ][ text (String.fromInt image.points) ]
            ]
            , span [ class "col-sm-4"
            , title "Favourites" ][
              Icons.heart |> Icons.withSize 15 |> Icons.withStrokeWidth 2 |> Icons.toHtml [] 
              , b [ style "margin-left" "5px"
              , style "font-size" "15px" ][ text (String.fromInt 0) ]
            ]
          ]
        ]
      ]
    ]   
  ]

trimString: String -> String
trimString string =
  if String.length string > 25 then
    String.append (String.slice 0 25 string) "..."
  else
    string

decodePreviewContainer: Decode.Decoder PreviewContainer
decodePreviewContainer =
  Decode.succeed PreviewContainer
    |> required "total" Decode.int
    |> required "images" (Decode.list decodePreview)

decodePreview: Decode.Decoder Preview
decodePreview =
    Decode.succeed Preview
        |> required "id" Decode.string
        |> required "title" Decode.string
        |> required "file" Decode.string
        |> optional "author" Decode.string "Anonymous"
        |> required "points" Decode.int
        |> required "views" Decode.int
        |> required "uploaded" DecodeExtra.datetime

decodeImage: Decode.Decoder Model
decodeImage =
    Decode.succeed Model
        |> required "title" Decode.string
        |> required "file" Decode.string
        |> required "id" Decode.string
        |> optional "description" Decode.string "No description"
        |> optional "author" Decode.string "Anonymous"
        |> optional "tags" (Decode.list Decode.string) []
        |> required "points" Decode.int
        |> required "views" Decode.int
        |> required "uploaded" DecodeExtra.datetime