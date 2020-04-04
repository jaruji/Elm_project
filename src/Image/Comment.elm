module Image.Comment exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)

type alias Model =
  { 
    content: String
    , username: String
    , url: String
  }

commentDecoder: Decode.Decoder Model
commentDecoder =
    Decode.succeed Model
        |> required "content" Decode.string 
        |> required "username" Decode.string
        |> required "url" Decode.string
