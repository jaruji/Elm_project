port module Query exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode exposing(..)

--port function that stores query state in Session Storage
port saveState: Encode.Value -> Cmd msg

--request JavaScript to send us the potentially stored state
port request: () -> Cmd msg

--restore the state we receive from JavaScript
port restoreState: (Maybe Encode.Value -> msg) -> Sub msg

encode: String -> Int -> Encode.Value
encode query page =
    -- Store query state as json, so we can store multiple values
    Encode.object[
        ("query", Encode.string query)
        , ("page", Encode.int page)
    ]

decodeQuery: Encode.Value -> String
decodeQuery json =
    --decode the query parameter after retrieving state
    case decodeValue (at ["query"] Decode.string) json of 
        Err _ ->
            ""
        Ok a ->
            a

decodePage: Encode.Value -> Int
decodePage json = 
    --decode the page parameter after retrieving state
    case decodeValue (at ["page"] Decode.int) json of 
        Err _ ->
            1
        Ok a ->
            a