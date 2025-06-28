import Foundation
import Supabase

enum SupabaseConfig {
    static let supabaseURL = "https://etzdkvwucgaznmolqdyj.supabase.co"
    static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0emRrdnd1Y2dhem5tb2xxZHlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAwOTM0OTAsImV4cCI6MjA2NTY2OTQ5MH0.Y2JPo9c8SKnxK9blYkkJRsIbJPnu4vnUb__AD9D6LwM"
    
    static let client = SupabaseClient(
        supabaseURL: URL(string: supabaseURL)!,
        supabaseKey: supabaseKey
    )
} 
