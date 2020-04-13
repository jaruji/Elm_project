module Image.Stats exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Decode.Extra as DecodeExtra
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import FeatherIcons as Icons

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

view: Model -> Html msg
view model =
    div[][
        span [ class "col-sm-4"
        , title "Views" ][
          Icons.eye |> Icons.withSize 20 |> Icons.withStrokeWidth 2 |> Icons.toHtml [] 
          , b [ style "margin-left" "5px"
          , style "font-size" "15px" ][ text (String.fromInt model.views) ]
        ]
        , span [ class "col-sm-4"
        , title "Points" ][
          Icons.award |> Icons.withSize 20 |> Icons.withStrokeWidth 2 |> Icons.toHtml [] 
          , b [ style "margin-left" "5px"
          , style "font-size" "15px" ][ text (String.fromInt model.points) ]
        ]
        , span [ class "col-sm-4"
        , title "Favourites" ][
          Icons.heart |> Icons.withSize 20 |> Icons.withStrokeWidth 2 |> Icons.toHtml [] 
          , b [ style "margin-left" "5px"
          , style "font-size" "15px" ][ text (String.fromInt model.favorites) ]
        ]
    ]