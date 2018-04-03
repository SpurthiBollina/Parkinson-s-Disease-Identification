# Parkinsons-Disease-Identification using Unsupervised ML Techniques
Improving machine learning model which identifies Parkinson's disease which will lead to helping patients with early diagnosis and reduction of treatment cost. Implemented an unsupervised classification on the dynamic spiral drawings of the Parkinson’s test dataset, and classify normal people from Parkinson’s disease ones. 

## Approach
Implemented distance based clustering techniques to classify the given drawings. Converted images to their pixel data and implemented t-SNE dimensionality reduction technique to bring down to [25 X 2] dimensions. This helped me visualize the image data in 2 dimensions and better understand the data spread.
Scaled the data and explored multiple clustering techniques (Kmeans, Hierarchical, DBSCAN and Spectral) and tuned the models for better classification. Tested including the Static Spiral drawings and provided my observations.   

#### Steps Involved <br />
	Loaded images and converted to data frame
	Data Exploration
	Feature Generation
	Dimensionality Reduction using t-SNE technique
	Clustered on Dynamic Spiral Drawings
	Evaluated including Static Spiral Drawings


