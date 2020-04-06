module Image.Comment exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Decode.Extra as DecodeExtra
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import Time

type alias Model =
  { 
    content: String
    , username: String
    , url: String
    , date: Time.Posix
    , points: Int
  }

commentDecoder: Decode.Decoder Model
commentDecoder =
    Decode.succeed Model
        |> required "content" Decode.string 
        |> required "username" Decode.string
        |> optional "avatar" Decode.string "placeholder"
        |> required "uploaded" DecodeExtra.datetime
        |> required "points" Decode.int
