//
//  Supabase.swift
//  Safar
//
//  Created by Arman Kassam on 2025-07-29.
//

import Foundation
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "SUPABASE_URL")!,
  supabaseKey: "SUPABASE_ANON_KEY"
)
