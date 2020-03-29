port module User exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Time exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import Server

--Model

type alias Model =
  {
    username: String
    --, password: String
    , email: String
    , avatar: String
    , bio: String
    , verif: Bool
    , firstName: Maybe String
    , surname: Maybe String
    , occupation: Maybe String
    , facebook: Maybe String
    , twitter: Maybe String
    , github: Maybe String
    , token: String
    --, history: List String
  }

decodeUser: Decode.Decoder Model
decodeUser =
    Decode.succeed Model
        |> required "username" Decode.string 
        |> required "email" Decode.string
        |> optional "profilePic" Decode.string (Server.url ++ "/img/profile/default.jpg")
        |> optional "bio" Decode.string "No description"
        |> required "verif" Decode.bool
        |> required "firstName" (nullable Decode.string)
        |> required "surname" (nullable Decode.string)
        |> required "occupation" (nullable Decode.string)
        |> required "facebook" (nullable Decode.string)
        |> required "twitter" (nullable Decode.string)
        |> required "github" (nullable Decode.string)
        |> required "token" Decode.string

port storeToken : Maybe String -> Cmd msg

encodeForStorage: Model -> Cmd msg
encodeForStorage user =
    storeToken (Just user.token)

logout : Cmd msg
logout = 
    storeToken Nothing