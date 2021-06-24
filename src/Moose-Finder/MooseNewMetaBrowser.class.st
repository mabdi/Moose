Class {
	#name : #MooseNewMetaBrowser,
	#superclass : #SpPresenter,
	#instVars : [
		'hierarchy',
		'properties',
		'map',
		'entityInformation',
		'metamodel'
	],
	#category : #'Moose-Finder'
}

{ #category : #specs }
MooseNewMetaBrowser class >> defaultSpec [

	^ SpPanedLayout newHorizontal
		  add: (SpPanedLayout newVertical
				   add: (SpPanedLayout newHorizontal
						    add: #hierarchy;
						    position: 40 percent;
						    add: #properties;
						    yourself);
				   add: #map;
				   yourself);
		  position: 75 percent;
		  add: #entityInformation;
		  yourself
]

{ #category : #'world menu' }
MooseNewMetaBrowser class >> menuBrowseMetaOn: aBuilder [

	<worldMenu>
	^ (MooseModel developerTool: self menuCommandOn: aBuilder)
		  order: 35;
		  help: 'Famix compatiblity meta-model browser';
		  withSeparatorAfter;
		  yourself
]

{ #category : #'world menu' }
MooseNewMetaBrowser class >> menuLabel [

	^ 'Meta Browser'
]

{ #category : #'instance creation' }
MooseNewMetaBrowser class >> open [

	<script>
	^ (self on: (MooseModel withAllSubclasses reject: [ :model | 
			    model isDeprecated or: [ model isTestModel ] ]) flatten)
		  openWithSpec
]

{ #category : #specs }
MooseNewMetaBrowser class >> title [

	^ 'Moose Meta Browser'
]

{ #category : #specs }
MooseNewMetaBrowser class >> windowSize [

	^ 1000 @ 500
]

{ #category : #initialization }
MooseNewMetaBrowser >> connectPresenters [

	hierarchy whenSelectionChangedDo: [ 
		self updatePropertiesTitles.
		self update ]
]

{ #category : #initialization }
MooseNewMetaBrowser >> initializeHierarchy [

	hierarchy := self newTreeTable
		             roots: ((metamodel classes select: [ :class | 
					               class superclass = FM3Object instance ]) 
				              sortAscending: #fullName);
		             children: [ :class | 
			             class subclasses sortAscending: #fullName ];
		             addColumn:
			             ((SpStringTableColumn
				               title: 'Entity'
				               evaluated: #fullName) displayItalic: #isAbstract);
		             addColumn:
			             (SpStringTableColumn
				              title: 'Package'
				              evaluated: [ :class | 
					              class package
						              ifNil: [ '' ]
						              ifNotNil: [ class package name ] ]);
		             beResizable
]

{ #category : #initialization }
MooseNewMetaBrowser >> initializePresenters [

	super initializePresenters.
	self initializeHierarchy.
	self initializeProperties.
	map := self instantiate: SpRoassalPresenter.
	entityInformation := self newNotebook
]

{ #category : #initialization }
MooseNewMetaBrowser >> initializeProperties [

	properties := self newNotebook
		              addPage: self tableOfRelations;
		              addPage: self tableOfProperties;
		              addPage: self tableOfMethods
]

{ #category : #initialization }
MooseNewMetaBrowser >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter initialExtent: self class windowSize
]

{ #category : #'properties table' }
MooseNewMetaBrowser >> propertyClassColumn [

	^ (SpStringTableColumn
		   title: 'Class'
		   evaluated: [ :property | property mmClass name ])
		  beSortable;
		  displayItalic: [ :property | 
			  property mmClass == hierarchy selectedItem ]
]

{ #category : #'properties table' }
MooseNewMetaBrowser >> propertyNameColumn [

	^ (SpStringTableColumn title: 'Name' evaluated: #name)
		  displayItalic: [ :property | 
			  property compiledMethod isNotNil and: [ 
					  property compiledMethod isDeprecated ] ];
		  beSortable
]

{ #category : #'properties table' }
MooseNewMetaBrowser >> propertyTypeColumn [

	^ (SpCompositeTableColumn title: 'Type')
		  addColumn:
			  (SpStringTableColumn evaluated: [ :property | property type name ]);
		  addColumn: (SpStringTableColumn evaluated: [ :property | 
					   property isMultivalued
						   ifTrue: [ '*' ]
						   ifFalse: [ '' ] ]);
		  addColumn: (SpStringTableColumn evaluated: [ :property | 
					   property isDerived
						   ifTrue: [ '/' ]
						   ifFalse: [ '' ] ]);
		  sortFunction: [ :property | property type name ] asSortFunction
]

{ #category : #'accessing model' }
MooseNewMetaBrowser >> setModelBeforeInitialization: aMetamodel [

	metamodel := aMetamodel
]

{ #category : #'properties table' }
MooseNewMetaBrowser >> tableOfMethods [

	| page |
	page := SpNotebookPage title: 'Methods' provider: [ 
		        self newTable addColumn:
			        ((SpStringTableColumn title: 'Name' evaluated: #selector)
				         displayItalic: [ :method | method isDeprecated ];
				         beSortable) ].

	page whenRetrievedDo: [ :table | 
		table items: (hierarchy selectedItem
				 ifNil: [ {  } ]
				 ifNotNil: [ :fm3Class | fm3Class implementingClass methods ]) ].

	^ page
]

{ #category : #'properties table' }
MooseNewMetaBrowser >> tableOfProperties [

	| page |
	page := SpNotebookPage title: 'Properties' provider: [ 
		        self newTable
			        beResizable;
			        addColumn: self propertyNameColumn;
			        addColumn: self propertyClassColumn;
			        addColumn: self propertyTypeColumn ].


	page whenRetrievedDo: [ :table | 
		table items: (hierarchy selectedItem
				 ifNil: [ {  } ]
				 ifNotNil: [ :fm3Class | 
				 fm3Class allPrimitiveProperties sorted: #name ascending ]) ].
	^ page
]

{ #category : #'properties table' }
MooseNewMetaBrowser >> tableOfRelations [

	| page |
	page := SpNotebookPage title: 'Relations' provider: [ 
		        self newTable
			        beResizable;
			        addColumn: self propertyNameColumn;
			        addColumn: self propertyClassColumn;
			        addColumn: self propertyTypeColumn;
			        addColumn:
				        (SpStringTableColumn
					         title: 'Opposite'
					         evaluated: [ :property | 
						         property opposite
							         ifNotNil: [ :opposite | opposite name ]
							         ifNil: [ '' ] ]) beSortable ].

	page whenRetrievedDo: [ :table | 
		table items: (hierarchy selectedItem
				 ifNil: [ {  } ]
				 ifNotNil: [ :fm3Class | 
				 fm3Class allComplexProperties sorted: #name ascending ]) ].
	^ page
]

{ #category : #'properties table' }
MooseNewMetaBrowser >> titlesForEmptyProperties [

	^ { 'Relations'. 'Properties'. 'Methods' }
]

{ #category : #'properties table' }
MooseNewMetaBrowser >> titlesForPropertiesOf: fm3Class [

	^ { 
		  (fm3Class allComplexProperties size asString , ' ' , 'Relations').
		  (fm3Class allPrimitiveProperties size asString , ' '
		   , 'Properties').
		  (fm3Class implementingClass methods size asString , ' '
		   , 'Methods') }
]

{ #category : #'properties table' }
MooseNewMetaBrowser >> updatePropertiesTitles [

	| titles |
	titles := hierarchy selectedItem
		          ifNil: [ self titlesForEmptyProperties ]
		          ifNotNil: [ :fm3Class | 
		          self titlesForPropertiesOf: fm3Class ].
	properties pages
		with: titles
		do: [ :page :title | page title: title ]
]
