//
//  Datos.swift
//  Sensores9B
//
//  Created by metricka on 07/06/2024.
//

import UIKit

class Datos: NSObject 
{
    var latitud: Double!
    var longitud: Double!
    var codigoNuevo: Bool!
    static var datos: Datos!
    
    override init()
    {
        latitud = 0.0
        longitud = 0.0
        codigoNuevo = false
    }
    
    static func sharedDatos() -> Datos
    {
        if datos == nil
        {
            return Datos.init()
        }
        
        return datos
    }
    
    override var description: String
    {
        return "Latitud = \(String(latitud)) - Longitud = \(String(longitud))"
    }
}
