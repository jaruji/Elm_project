module Image exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import Server
import Image.Comment as Comment

type alias Model =
  {
    title: String
    , url: String
    , id: String
    , description: String
    , author: String
    , tags: List String
    , upvotes: Int
    , downvotes: Int
    , views: Int
    , comments: List Comment.Model
  }

decodeImage: Decode.Decoder Model
decodeImage =
    Decode.succeed Model
        |> required "title" Decode.string
        |> required "file" Decode.string
        |> required "id" Decode.string
        |> optional "description" Decode.string "No description"
        |> optional "author" Decode.string "Anonymous"
        |> optional "tags" (Decode.list Decode.string) []
        |> required "upvotes" Decode.int
        |> required "downvotes" Decode.int
        |> required "views" Decode.int
        |> optional "comments" (Decode.list Comment.commentDecoder) []