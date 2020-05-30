module Tag exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

{--
	Function used to display a signle tag. Is used in combination with List.map
	, so that we cant display a list of tags. If you click on a tag, url changes in a way
	that initiates the search of all images containing this tag.
--}
view: String -> Html msg
view value =
    a [ class "badge preview"
    , style "border" "none"
    , style "outline" "none"
    , style "background-color" "#3b5998"
    , style "margin" "1px"
    , href ("/tags?q=" ++ value)
    ][ text value ]