//
//  FavoriteButton.swift
//  Landmarks
//
//  Created by JORD on 3/5/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct FavoriteButton: View {
    @Binding var isSet: Bool
    
    var body : some View {
        Button {
            isSet.toggle()
        } label: {
            Label("Toggle Favorite", systemImage: isSet ? "star.fill" : "star")
                .labelStyle(.iconOnly)
                .foregroundStyle(isSet ? .yellow : .gray)
        }
    }
}

#Preview {
    FavoriteButton(isSet: .constant(true))
}
