module Tag exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


view: String -> Html msg
view value =
    a [ class "badge preview"
    , style "border" "none"
    , style "outline" "none"
    , style "background-color" "#3b5998"
    , style "margin" "1px"
    , href ("/search?q=" ++ value)
    ][ text value ]