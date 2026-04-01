//
//  SettingsView.swift
//  ximena
//

import SwiftUI

struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    
    var body: some View {
        
        GeometryReader{geometry in
            ScrollView{
                
                VStack{
                    
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                
            }
            
        }
    }
    
}
