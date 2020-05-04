port module Query exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode exposing(..)

port saveState: Encode.Value -> Cmd msg

port request: () -> Cmd msg

port restoreState: (Maybe Encode.Value -> msg) -> Sub msg

encode: String -> Int -> Encode.Value
encode query page =
    Encode.object[
        ("query", Encode.string query)
        , ("page", Encode.int page)
    ]

decodeQuery: Encode.Value -> String
decodeQuery json =
    case decodeValue (at ["query"] Decode.string) json of 
        Err _ ->
            ""
        Ok a ->
            a

decodePage: Encode.Value -> Int
decodePage json = 
    case decodeValue (at ["page"] Decode.int) json of 
        Err _ ->
            1
        Ok a ->
            a