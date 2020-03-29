module Pages.Upload exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import File exposing (File)
import File.Select as Select
import Task
import User
import Server

type alias Model =
  { hover : Bool
  , previews : List String
  , key : Nav.Key
  , user : Maybe User.Model
  }


init : Maybe User.Model -> Nav.Key -> (Model, Cmd Msg)
init user key =
  (Model False [] key user, Cmd.none)

-- UPDATE


type Msg
  = Pick
  | DragEnter
  | DragLeave
  | GotFiles File (List File)
  | GotPreviews (List String)
  | Response (Result Http.Error())
  | Upload File


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
      , --Task.perform GotPreviews <| Task.sequence <|
          --List.map File.toUrl (file :: files)
        put file
      )

    GotPreviews urls ->
      ( { model | previews = urls }
      , Cmd.none
      )

    Upload file ->
      (model, put file)

    Response response ->
      case response of
        Ok string ->
          (model, Cmd.none)
        Err log ->
          (model, Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW

view : Model -> Html Msg
view model =
  case model.user of
    Just _ ->
      div[ style "text-align" "center" ][
        h1 [] [ text "Upload an image to our site"]
        , div
          [ style "border" (if model.hover then "6px dashed #2E86C1" else "6px dashed #ccc")
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
          [ button [ class "btn btn-primary", onClick Pick ] [ text "Select image" ]
          , div [ class "help-block" ] [ text "Drag and Drop an image here" ]
          , div
              [ style "display" "flex"
              , style "align-items" "center"
              , style "height" "60px"
              , style "padding" "20px"
              ]
              (List.map viewPreview model.previews)
          ]
          , button [ class "btn btn-primary" ] [ text "Upload" ] 
        ]
    Nothing ->
      div [] [ 
        a [ href "/sign_in" ] [ text "Sign In" ]
        , text " to upload images"
        , div [] [ text "Don't have an account yet? "
                 , a [ href "/sign_up" ] [ text "Sign Up" ] ]
      ]


viewPreview : String -> Html msg
viewPreview url =
  div []
    [ 
      img [src url, style "text-align" "center"] []
    ]


dropDecoder : Decode.Decoder Msg
dropDecoder =
  Decode.at ["dataTransfer","files"] (Decode.oneOrMore GotFiles File.decoder)


hijackOn : String -> Decode.Decoder msg -> Attribute msg
hijackOn event decoder =
  preventDefaultOn event (Decode.map hijack decoder)


hijack : msg -> (msg, Bool)
hijack msg =
  (msg, True)

put : File -> Cmd Msg
put file = 
  Http.request
    { method = "PUT"
    , headers = [ Http.header "name" (File.name file) ]
    , url = Server.url ++ "/upload/image"
    , body = Http.fileBody file
    , expect = Http.expectWhatever Response
    , timeout = Nothing
    , tracker = Nothing
    }