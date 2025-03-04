//
//  LandmarkRow.swift
//  Landmarks
//
//  Created by JORD on 3/3/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct LandmarkRow: View {
    var landmark: Landmark
    
    var body: some View {
        HStack {
            landmark.image
                .resizable()
                .frame(width: 50, height: 50)
                
            Text(landmark.name)
   
            Spacer()
        }

        
    }
}

#Preview {
    Group {
        LandmarkRow(landmark: ModelData.shared.landmarks[0])
        LandmarkRow(landmark: ModelData.shared.landmarks[1])
    }
}
