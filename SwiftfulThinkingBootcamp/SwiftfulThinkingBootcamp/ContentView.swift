//
//  ContentView.swift
//  SwiftfulThinkingBootcamp
//
//  Created by JORD on 1/23/25.
//

import SwiftUI

// Default Code
struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.green)
                .foregroundStyle(.tint)
            Text("Heyo, JORD!")
                .foregroundColor(.orange)
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

//// Code from ST
//struct ContentView: View {
//    var body: some View {
//        Text("Hi Jord")
//            .font(.title)
//            .fontWeight(.bold)
//            .foregroundColor(Color.red)
//            
//    }
//}
//
//struct ContentView_Previews:
//    PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
