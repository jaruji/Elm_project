module Image.Stats exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Decode.Extra as DecodeExtra
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)

type alias Model =
  {
    views: Int
    , points: Int
    , favorites: Int
  }

statsDecoder: Decode.Decoder Model
statsDecoder =
    Decode.succeed Model
        |> required "views" Decode.int 
        |> required "points" Decode.int
        |> optional "favorites" Decode.int 0