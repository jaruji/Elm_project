module Image.Stats exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Decode.Extra as DecodeExtra
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import FeatherIcons as Icons

--Model
type alias Model =
  {
    views: Int
    , points: Int
    , favorites: Int
  }

statsDecoder: Decode.Decoder Model
statsDecoder =
    {-- 
      Decode image stats as a separate "module". 
      Needed so that we can reload only image stats when we vote/favorite
    --}
    Decode.succeed Model
        |> required "views" Decode.int 
        |> required "points" Decode.int
        |> optional "favorites" Decode.int 0

--View
view: Model -> Html msg
view model =
    --display the stats separately from the image
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