module Image.Comment exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Decode.Extra as DecodeExtra
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import Time

--Model
type alias Model =
  { 
    content: String
    , username: String
    , url: String
    , date: Time.Posix
    , points: Int
    , id: String
    , edited: Maybe Time.Posix
  }

commentDecoder: Decode.Decoder Model
commentDecoder =
    {--
        We need to decode the comment json that received from the server.
        Value edited is only available if the comments has been edited at least once. 
    --}
    Decode.succeed Model
        |> required "content" Decode.string 
        |> required "username" Decode.string
        |> optional "avatar" Decode.string "placeholder"
        |> required "uploaded" DecodeExtra.datetime
        |> required "points" Decode.int
        |> required "_id" Decode.string
        |> optional "edited" (nullable DecodeExtra.datetime) Nothing
