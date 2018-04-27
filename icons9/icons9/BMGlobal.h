//
//  BMGlobal.h
//  icons9
//
//  Created by fenglh on 2018/4/27.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#ifndef BMGlobal_h
#define BMGlobal_h


typedef NS_ENUM(NSUInteger, BMImageType) {
    BMImageTypeUnknown = 0,
    BMImageTypeSVG = 1 << 0,
    BMImageTypePNG = 1 << 1,
    BMImageTypeJPG = 1 << 2,
    BMImageTypeAll = BMImageTypeSVG | BMImageTypePNG | BMImageTypeJPG,
};




#endif /* BMGlobal_h */
