//
//  CSMCollectionItemUpdate.swift
//  CSMCollectionBatchUpdates
//
//  Created by Carlos Simon Villas on 11/04/16.
//  Copyright © 2016 Charlisim. All rights reserved.
//

import Foundation


class CSMCollectionItemUpdate:CSMCollectionUpdate{
    var indexPath:NSIndexPath?
    var indexPathNew:NSIndexPath?
    override var itemUpdate:Bool {
        get{
            return true
        }
    }
    static func updateWithType(type:CSMCollectionUpdateType, indexPath:NSIndexPath?, newIndexPath:NSIndexPath?, object:AnyObject)->Self{
        return self.init(withType: type,
                            object: object,
                            indexPath: indexPath,
                            newIndexPath: newIndexPath)
    }
    
    required init(withType type: CSMCollectionUpdateType,
                          object: AnyObject,
                          indexPath:NSIndexPath?,
                          newIndexPath:NSIndexPath?) {
        self.indexPath = indexPath
        self.indexPathNew = newIndexPath
        super.init(withType: type, object: object)
        
    }
    
    
    
}