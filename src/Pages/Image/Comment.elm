import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (Decoder, field, string)
import Json.Encode exposing (..)
import Time exposing (..)

type alias Model = 
{
  author: String,
  --time: Time.Posix,
  upvotes: Int,
  downvotes: Int,
  body: String
}

init: Model
init =
  (Model "" 0 0 "" )


commentEncoder: Model -> Encode.Value
commentEncoder model =
  Encode.object
    [ ("author", Encode.string model.author),
    --("author", Encode.string model.author),
      ("author", Encode.int model.upvotes),
      ("author", Encode.int model.downvotes),
      ("author", Encode.string model.body),
    ]
