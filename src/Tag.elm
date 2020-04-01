module Tag exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


view: String -> Html msg
view value =
    span [ class "badge"
    , style "border" "none"
    , style "outline" "none"
    , style "background-color" "#3b5998"
    , style "margin" "1px"
    ][ text value ]