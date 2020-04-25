module Utils exposing (..)
import Http exposing (..)
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import FeatherIcons as Icons

info: Int -> String -> Html msg
info width text =
    div[][

    ]

success: Int -> String -> Html msg
success width text =
    div[][

    ]

warning: Int -> String -> Html msg
warning width text =
    div[][

    ]

error: Int -> String -> Html msg
error width text =
    div[][

    ]