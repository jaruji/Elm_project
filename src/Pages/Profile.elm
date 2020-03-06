import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, field, string, int, map3)



-- MAIN
--will contain information about user profile - retrieve information from HTTP server!