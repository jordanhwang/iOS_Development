//
//  TextBootcamp.swift
//  SwiftfulThinkingBootcamp
//
//  Created by JORD on 1/23/25.
//

import SwiftUI

struct TextBootcamp: View {
    var body: some View {
        Text("Hello, World! This is Jord!".lowercased())
//            .font(.body)
//            .fontWeight(.semibold)
//            .font(.system(size: 80, weight: .semibold, design: .serif))
//            .italic(false)
//            .strikethrough(false)
//            .underline(true, color: Color.green)

//            .kerning(10)
            .foregroundColor(.blue)
            .multilineTextAlignment(.leading)
//            .baselineOffset(100)
            .frame(width: 300, height: 100, alignment: .leading)
            .minimumScaleFactor(0.1)
    }
}

#Preview {
    TextBootcamp()
}
