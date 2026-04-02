//
//  FirstSettingsView.swift
//  ximena
//
//  Created by Salvatore De Rosa on 01/04/2026.
//

import SwiftUI


// ACCESSIBILITY SETTINGS MANAGEMENT FOR THE FIRST TIME OPENING THE APP
struct FirstSettingsView: View {
    var body: some View {
        
        GeometryReader { geometry in
            
            ScrollView{
                
                VStack{
                    
                    Text("First Settings View")
                    
                }
                .frame(maxWidth: . infinity, minHeight: geometry.size.height)
                
                
                
            }
            
            
        }
        
    }
}

#Preview {
    FirstSettingsView()
}
