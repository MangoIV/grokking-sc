{-# LANGUAGE OverloadedStrings #-}
{-|
Module      : Core.Pretty
Description : Prettyprint expressions of the core language.

This module implements a simple Wadler-Leijen-style prettyprinter for
expressions of the intermediate language Core.
-}
module Core.Pretty (render) where

import Core.Syntax
import Fun.Syntax (BinOp(..), Ctor(..), Dtor(..))
import Data.List (intersperse)
import Prettyprinter
import Prettyprinter.Render.String


doublerightarrow :: Doc ann
doublerightarrow = "⇒"
instance Pretty Ctor where
    pretty Nil = "Nil"
    pretty Cons = "Cons"
    pretty Tup = "Tup"

instance Pretty Dtor where
    pretty Hd = "hd"
    pretty Tl = "tl"
    pretty Fst = "fst"
    pretty Snd = "snd"
    pretty Ap = "ap"

instance Pretty a => Pretty (Pattern a) where
    pretty MkPattern{xtor = nm, patv = [], patcv = [], patst = st} =
        pretty nm <+> doublerightarrow <+> pretty st
    pretty MkPattern{xtor = nm, patv = vars, patcv = covars, patst = st} =
        pretty nm
            <> parens (hcat (intersperse comma (pretty <$> vars)) <> semi <> hcat (intersperse comma (pretty <$> covars)))
            <+> doublerightarrow
            <+> pretty st

instance Pretty Producer where
    pretty (Var v) = pretty v
    pretty (Lit n) = pretty n
    pretty (Mu cv st) = "μ" <> pretty cv <> dot <+> pretty st
    pretty (Constructor ct [][]) = pretty ct
    pretty (Constructor ct pargs cargs) =
        pretty ct <> parens (hcat (intersperse comma (pretty <$> pargs)) <> semi <> hcat (intersperse comma (pretty <$> cargs)))
    pretty (Cocase patterns) = "cocase" <+> braces (hcat (intersperse comma (pretty <$> patterns)))

instance Pretty Consumer where
    pretty (Covar cv) = pretty cv
    pretty (MuTilde v st) = "~μ" <> pretty v <> dot <+> pretty st
    pretty (Case patterns) = "case" <+> braces (hcat (intersperse comma (pretty <$> patterns)))
    pretty (Destructor dt pargs cargs) =
        pretty dt <> parens ( hcat (intersperse comma (pretty <$> pargs)) <> semi <> hcat (intersperse comma (pretty <$> cargs)))

instance Pretty Statement where
    pretty (Cut p c) = "〈" <+> pretty p <+> "|" <+> pretty c <+> "〉"
    pretty (Op p1 Prod p2 c) = "*" <> parens (pretty p1 <> comma <> pretty p2 <> semi <> pretty c)
    pretty (Op p1 Sum p2 c)  = "+" <> parens (pretty p1 <> comma <> pretty p2 <> semi <> pretty c)
    pretty (Op p1 Sub p2 c)  = "-" <> parens (pretty p1 <> comma <> pretty p2 <> semi <> pretty c)
    pretty (IfZ p1 s1 s2)  = "ifz" <> parens (pretty p1 <> semi <> pretty s1 <> comma <> pretty s2)
    pretty (Fun nm pargs cargs) =
        pretty nm <> parens (hcat (intersperse comma (pretty <$> pargs)) <> semi <> hcat (intersperse comma (pretty <$> cargs)))
    pretty Done = "Done"


instance (Pretty a) => Pretty (Def a) where
    pretty (Def name pargs cargs body) =
        let args = hcat (intersperse comma (pretty . fst <$> pargs)) <> semi <> hcat (intersperse comma (pretty . fst <$> cargs)) in
        "def" <+> pretty name <> parens args <+> ":=" <+> pretty body

instance (Pretty a) => Pretty (Prog a) where
    pretty (MkProg defs) = vcat (pretty <$> defs)

render :: Pretty a => a -> String
render x = renderString (layoutPretty defaultLayoutOptions (pretty x))