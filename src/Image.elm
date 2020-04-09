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
import Time

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
  }


decodePreview: Decode.Decoder Preview
decodePreview =
    Decode.succeed Preview
        |> required "id" Decode.string
        |> required "title" Decode.string
        |> required "file" Decode.string
        |> optional "author" Decode.string "Anonymous"
        |> required "points" Decode.int
        |> required "views" Decode.int

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