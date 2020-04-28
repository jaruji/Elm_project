port module Query exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)

type alias Model = 
    {
        query: String
        , page: Int
    }

port saveState: Encode.Value -> Cmd msg

port request: () -> Cmd msg

port restoreState: (Maybe Encode.Value -> msg) -> Sub msg

encode: String -> Int -> Encode.Value
encode query page =
    Encode.object[
        ("query", Encode.string query)
        , ("page", Encode.int page)
    ]

decode: Decode.Decoder Model
decode =
    Decode.succeed Model
    |> required "query" Decode.string
    |> required "page" Decode.int
