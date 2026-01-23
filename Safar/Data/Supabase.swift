//
//  Supabase.swift
//  Safar
//
//  Created by Arman Kassam on 2025-07-29.
//

import Foundation
import Supabase

let supabaseBaseURL = URL(string: "https://nuywagndcbujbqneglje.supabase.co")!

let supabase = SupabaseClient(
  supabaseURL: supabaseBaseURL,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51eXdhZ25kY2J1amJxbmVnbGplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMjYzODMsImV4cCI6MjA2ODgwMjM4M30.R25FLGNrhBra1LiugbcpYDsuxdc7FYtD-kJdYfeh100"
)
