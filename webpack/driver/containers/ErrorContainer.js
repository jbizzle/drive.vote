import React from 'react';
import autobind from 'autobind-decorator';
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';


@autobind
class ErrorContainer extends React.Component {
    render() {
        if (this.props.errorState) {
            return (
                <div>
                    <ReactCSSTransitionGroup 
                        transitionName="banner" 
                        transitionAppear={true} 
                        transitionAppearTimeout={500}>
                        <div className="errorBanner" key={1}>
                            <i className="fa fa-exclamation"></i> {this.props.errorState}
                            <a className="pull-right" onClick={this.props.clearError}><i className="fa fa-close"></i></a>
                        </div>       
                    </ReactCSSTransitionGroup>
                </div>
            )
        } else {
            return null
        }
    }
};

export default ErrorContainer;
