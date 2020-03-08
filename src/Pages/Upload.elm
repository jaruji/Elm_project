module Pages.Upload exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import File exposing (File)
import File.Select as Select
import Task

type alias Model =
  { hover : Bool
  , previews : List String
  }


init : (Model, Cmd Msg)
init =
  (Model False [], Cmd.none)

-- UPDATE


type Msg
  = Pick
  | DragEnter
  | DragLeave
  | GotFiles File (List File)
  | GotPreviews (List String)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Pick ->
      ( model
      , Select.files ["image/*"] GotFiles
      )

    DragEnter ->
      ( { model | hover = True }
      , Cmd.none
      )

    DragLeave ->
      ( { model | hover = False }
      , Cmd.none
      )

    GotFiles file files ->
      ( { model | hover = False }
      , Task.perform GotPreviews <| Task.sequence <|
          List.map File.toUrl (file :: files)
      )

    GotPreviews urls ->
      ( { model | previews = urls }
      , Cmd.none
      )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW

view : Model -> Html Msg
view model =
  div
    [ style "border" (if model.hover then "6px dashed purple" else "6px dashed #ccc")
    , style "border-radius" "20px"
    , style "width" "480px"
    , style "margin" "100px auto"
    , style "padding" "40px"
    , style "display" "flex"
    , style "flex-direction" "column"
    , style "justify-content" "center"
    , style "align-items" "center"
    , hijackOn "dragenter" (Decode.succeed DragEnter)
    , hijackOn "dragover" (Decode.succeed DragEnter)
    , hijackOn "dragleave" (Decode.succeed DragLeave)
    , hijackOn "drop" dropDecoder
    ]
    [ button [ class "btn-primary", onClick Pick ] [ text "Select image" ]
    , div
        [ style "display" "flex"
        , style "align-items" "center"
        , style "height" "60px"
        , style "padding" "20px"
        ]
        (List.map viewPreview model.previews)
    ]


viewPreview : String -> Html msg
viewPreview url =
  div
    [ style "width" "60px"
    , style "height" "60px"
    , style "background-image" ("url('" ++ url ++ "')")
    , style "background-position" "center"
    , style "background-repeat" "no-repeat"
    , style "background-size" "contain"
    ]
    []


dropDecoder : Decode.Decoder Msg
dropDecoder =
  Decode.at ["dataTransfer","files"] (Decode.oneOrMore GotFiles File.decoder)


hijackOn : String -> Decode.Decoder msg -> Attribute msg
hijackOn event decoder =
  preventDefaultOn event (Decode.map hijack decoder)


hijack : msg -> (msg, Bool)
hijack msg =
  (msg, True)
